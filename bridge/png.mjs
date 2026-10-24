import {inflateSync,deflateSync} from 'node:zlib';
// Penpot's PNG exports are non-interlaced, 8-bit RGB/RGBA; indexed PNGs are accepted too.
export function decodePNG(bytes){
 const b=Buffer.from(bytes);if(!b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error('Expected PNG');
 let width,height,depth,type,interlace,palette,alpha;const data=[];
 for(let o=8;o+12<=b.length;){const len=b.readUInt32BE(o),name=b.toString('ascii',o+4,o+8);if(o+12+len>b.length)throw Error('Truncated PNG');const v=b.subarray(o+8,o+8+len);if(name==='IHDR'){width=v.readUInt32BE(0);height=v.readUInt32BE(4);depth=v[8];type=v[9];interlace=v[12]}if(name==='IDAT')data.push(v);if(name==='PLTE')palette=v;if(name==='tRNS')alpha=v;o+=12+len;}
 if(!width||!height||width>1024||height>1024||depth!==8||interlace!==0||![0,2,3,4,6].includes(type))throw Error('PNG must be non-interlaced 8-bit and at most 1024×1024');
 const channels=({0:1,2:3,3:1,4:2,6:4})[type],stride=width*channels,raw=inflateSync(Buffer.concat(data),{maxOutputLength:(stride+1)*height});
 if(raw.length!==(stride+1)*height)throw Error('Invalid PNG scanlines');
 const scan=Buffer.alloc(stride*height),pixels=Buffer.alloc(width*height*4);
 const paeth=(a,b,c)=>{const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c};
 for(let y=0;y<height;y++){const filter=raw[y*(stride+1)];if(filter>4)throw Error('Invalid PNG filter');for(let x=0;x<stride;x++){const a=x>=channels?scan[y*stride+x-channels]:0,up=y?scan[(y-1)*stride+x]:0,c=y&&x>=channels?scan[(y-1)*stride+x-channels]:0;scan[y*stride+x]=(raw[y*(stride+1)+1+x]+([0,a,up,Math.floor((a+up)/2),paeth(a,up,c)][filter]))&255;}}
 for(let i=0;i<width*height;i++){const o=i*channels,p=i*4;if(type===6){scan.copy(pixels,p,o,o+4)}else if(type===2){scan.copy(pixels,p,o,o+3);pixels[p+3]=255}else if(type===3){const ix=scan[o];if(!palette||ix*3+2>=palette.length)throw Error('Missing PNG palette');palette.copy(pixels,p,ix*3,ix*3+3);pixels[p+3]=alpha?.[ix]??255}else{pixels[p]=pixels[p+1]=pixels[p+2]=scan[o];pixels[p+3]=type===4?scan[o+1]:255}}
 return {width,height,pixels};
}
export function normalizeRaster(image,viewBox,shapeWidth,shapeHeight,degrees=0){
 const [x,y,w,h]=viewBox;if(![x,y,w,h,shapeWidth,shapeHeight,degrees].every(Number.isFinite)||w<=0||h<=0)throw Error('Invalid raster geometry');
 const angle=degrees*Math.PI/180,c=Math.cos(angle),s=Math.sin(angle),cx=shapeWidth/2,cy=shapeHeight/2;
 const inverse=(px,py)=>[c*(px-cx)+s*(py-cy)+cx,-s*(px-cx)+c*(py-cy)+cy];
 const corners=[[x,y],[x+w,y],[x,y+h],[x+w,y+h]].map(([a,b])=>inverse(a,b));
 const left=Math.min(...corners.map(p=>p[0])),top=Math.min(...corners.map(p=>p[1]));
 const width=Math.max(...corners.map(p=>p[0]))-left,height=Math.max(...corners.map(p=>p[1]))-top;
 const scale=Math.min(image.width/w,image.height/h,1024/width,1024/height),pw=Math.max(1,Math.round(width*scale)),ph=Math.max(1,Math.round(height*scale));
 const pixels=Buffer.alloc(pw*ph*4);
 for(let py=0;py<ph;py++)for(let px=0;px<pw;px++){
  const lx=left+(px+.5)*width/pw-cx,ly=top+(py+.5)*height/ph-cy;
  const sx=((c*lx-s*ly+cx-x)/w)*image.width-.5,sy=((s*lx+c*ly+cy-y)/h)*image.height-.5;
  const ix=Math.round(sx),iy=Math.round(sy);if(ix<0||iy<0||ix>=image.width||iy>=image.height)continue;
  image.pixels.copy(pixels,(py*pw+px)*4,(iy*image.width+ix)*4,(iy*image.width+ix)*4+4);
 }
 return {width:pw,height:ph,pixels,bounds:{x:left,y:top,width,height}};
}
const crcTable=Array.from({length:256},(_,n)=>{let c=n;for(let i=0;i<8;i++)c=c&1?0xedb88320^(c>>>1):c>>>1;return c>>>0});
function chunk(type,data){const name=Buffer.from(type),length=Buffer.alloc(4);length.writeUInt32BE(data.length);let crc=0xffffffff;for(const v of Buffer.concat([name,data]))crc=crcTable[(crc^v)&255]^(crc>>>8);const sum=Buffer.alloc(4);sum.writeUInt32BE((crc^0xffffffff)>>>0);return Buffer.concat([length,name,data,sum])}
export function encodePNG({width,height,pixels}){
 if(width<1||height<1||width>1024||height>1024||pixels.length!==width*height*4)throw Error('Invalid PNG pixels');
 const header=Buffer.alloc(13);header.writeUInt32BE(width,0);header.writeUInt32BE(height,4);header[8]=8;header[9]=6;
 const scan=Buffer.alloc((width*4+1)*height);for(let y=0;y<height;y++)pixels.copy(scan,y*(width*4+1)+1,y*width*4,(y+1)*width*4);
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(scan)),chunk('IEND',Buffer.alloc(0))]);
}
