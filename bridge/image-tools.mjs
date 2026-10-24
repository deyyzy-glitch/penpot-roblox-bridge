// Pixel transforms operate on detached copies and never change the source alpha.
export function monochromeColor(image){
 let best=-1,alpha=0;const p=image.pixels;
 for(let i=0;i<p.length;i+=4)if(p[i+3]>alpha){alpha=p[i+3];best=i}
 if(best<0)return null;
 for(let i=0;i<p.length;i+=4)if(p[i+3]>=16&&[0,1,2].some(k=>Math.abs(p[i+k]-p[best+k])>3))return null;
 return '#'+[0,1,2].map(k=>p[best+k].toString(16).padStart(2,'0')).join('').toUpperCase();
}
export function dilateRGB(image,radius=8){
 const {width:w,height:h,pixels:p}=image,n=w*h,queue=new Int32Array(n),distance=new Int16Array(n);distance.fill(-1);let head=0,tail=0;
 for(let i=0;i<n;i++)if(p[i*4+3]){queue[tail++]=i;distance[i]=0}
 while(head<tail){const i=queue[head++],d=distance[i];if(d>=radius)continue;const x=i%w,y=Math.floor(i/w);
  for(const j of [x?i-1:-1,x<w-1?i+1:-1,y?i-w:-1,y<h-1?i+w:-1])if(j>=0&&distance[j]<0){distance[j]=d+1;for(let k=0;k<3;k++)p[j*4+k]=p[i*4+k];queue[tail++]=j}
 }
 return image;
}
function boxBlur(src,w,h,r,horizontal){
 const out=new Float32Array(src.length),lines=horizontal?h:w,length=horizontal?w:h,step=horizontal?1:w,denom=2*r+1;
 for(let line=0;line<lines;line++){const start=horizontal?line*w:line;let sum=0;for(let k=0;k<=Math.min(r,length-1);k++)sum+=src[start+k*step];for(let k=0;k<length;k++){out[start+k*step]=sum/denom;const remove=k-r,add=k+r+1;if(remove>=0)sum-=src[start+remove*step];if(add<length)sum+=src[start+add*step]}}
 return out;
}
export function silhouetteGlow(image,radius){
 if(!Number.isFinite(radius)||radius<1||radius>32)throw Error('Glow radius must be 1–32 design pixels');
 const b=image.bounds,density=Math.min(image.width/b.width,image.height/b.height),r0=Math.max(1,Math.round(radius*density/2));
 const scale=Math.min(1,1024/(image.width+6*r0),1024/(image.height+6*r0));const r=Math.max(1,Math.round(r0*scale)),pad=3*r;
 const iw=Math.min(1024-2*pad,Math.max(1,Math.floor(image.width*scale))),ih=Math.min(1024-2*pad,Math.max(1,Math.floor(image.height*scale))),w=iw+2*pad,h=ih+2*pad;
 let alpha=new Float32Array(w*h);
 for(let y=0;y<ih;y++)for(let x=0;x<iw;x++){const sx=Math.min(image.width-1,Math.floor(x*image.width/iw)),sy=Math.min(image.height-1,Math.floor(y*image.height/ih));alpha[(y+pad)*w+x+pad]=image.pixels[(sy*image.width+sx)*4+3]}
 for(let pass=0;pass<3;pass++){alpha=boxBlur(alpha,w,h,r,true);alpha=boxBlur(alpha,w,h,r,false)}
 const pixels=Buffer.alloc(w*h*4);for(let i=0;i<w*h;i++){pixels[i*4]=pixels[i*4+1]=pixels[i*4+2]=255;pixels[i*4+3]=Math.round(alpha[i])}
 const sx=iw/b.width,sy=ih/b.height;
 return {width:w,height:h,pixels,bounds:{x:b.x-pad/sx,y:b.y-pad/sy,width:w/sx,height:h/sy}};
}
export function processImage(image,options={}){
 const result={...image,pixels:Buffer.from(image.pixels)};let tintColor=null;
 if(options.tint===true){tintColor=monochromeColor(result);if(tintColor)for(let i=0;i<result.pixels.length;i+=4)result.pixels[i]=result.pixels[i+1]=result.pixels[i+2]=255;}
 if(options.dilate===true&&!tintColor)dilateRGB(result);
 const glow=options.glow?silhouetteGlow(image,options.glow.radius):null;
 return {image:result,tintColor,glow};
}
