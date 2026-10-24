/* Corner geometry adapted from Supercorner/figma-squircle. See THIRD-PARTY-NOTICES.md. */
globalThis.P2RCorners=(()=>{
 function path(w,h,radii,smoothing){
  const r=radii.map(v=>Math.max(0,Math.min(v,Math.min(w,h)/2))),s=Math.max(0,Math.min(smoothing,.999999));
  const params=r.map(radius=>{
   if(!radius)return {r:0,p:0};
   const smooth=Math.min(s,Math.min(w,h)/2/radius-1),p=(1+smooth)*radius;
   const arc=Math.sin(Math.PI/4*(1-smooth))*radius*Math.SQRT2;
   const c=radius*Math.tan(Math.PI/8*smooth)*Math.cos(Math.PI/4*smooth),d=c*Math.tan(Math.PI/4*smooth);
   const b=(p-arc-c-d)/3;return {r:radius,p,a:2*b,b,c,d,arc};
  });
  const corner=(v,i)=>{if(!v.r)return '';const {a,b,c,d,arc,r}=v,ab=a+b,abc=ab+c,cb=c+b,cba=cb+a;
   return [
    `c ${a} 0 ${ab} 0 ${abc} ${d} a ${r} ${r} 0 0 1 ${arc} ${arc} c ${d} ${c} ${d} ${cb} ${d} ${cba}`,
    `c 0 ${a} 0 ${ab} ${-d} ${abc} a ${r} ${r} 0 0 1 ${-arc} ${arc} c ${-c} ${d} ${-cb} ${d} ${-cba} ${d}`,
    `c ${-a} 0 ${-ab} 0 ${-abc} ${-d} a ${r} ${r} 0 0 1 ${-arc} ${-arc} c ${-d} ${-c} ${-d} ${-cb} ${-d} ${-cba}`,
    `c 0 ${-a} 0 ${-ab} ${d} ${-abc} a ${r} ${r} 0 0 1 ${arc} ${-arc} c ${c} ${-d} ${cb} ${-d} ${cba} ${-d}`][i];};
  const [tl,tr,br,bl]=params;
  return `M ${tl.p} 0 L ${w-tr.p} 0 ${corner(tr,0)} L ${w} ${h-br.p} ${corner(br,1)} L ${bl.p} ${h} ${corner(bl,2)} L 0 ${tl.p} ${corner(tl,3)} Z`;
 }
 function surface(spec){
  const {radii,smoothing,fill,stroke}=spec;
  if(!Array.isArray(radii)||radii.length!==4||!radii.every(v=>Number.isFinite(v)&&v>=0&&v<=120)||!Number.isFinite(smoothing)||smoothing<0||smoothing>1)throw Error('Invalid smooth corner geometry');
  const paint=p=>{if(!p||!/^#[0-9a-f]{6}$/i.test(p.color)||!Number.isFinite(p.opacity)||p.opacity<0||p.opacity>1)throw Error('Invalid corner paint');return p};paint(fill);if(stroke){paint(stroke);if(!Number.isFinite(stroke.width)||stroke.width<0||stroke.width>120)throw Error('Invalid corner stroke');}
  const ext=radii.map(v=>Math.ceil(Math.max(v*(1+smoothing),stroke?.width||0))+1),[tl,tr,br,bl]=ext;
  const w=Math.max(tl,bl)+Math.max(tr,br)+2,h=Math.max(tl,tr)+Math.max(bl,br)+2;
  let svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${w*2}" height="${h*2}" viewBox="0 0 ${w} ${h}">`;
  const outer=path(w,h,radii,smoothing);
  svg+=`<path d="${outer}" fill="${fill.color}" fill-opacity="${fill.opacity}"/>`;
  if(stroke){const t=stroke.width;if(!Number.isFinite(t)||t<0||t>Math.min(w,h)/2)throw Error('Invalid corner stroke');
   const inner=path(w-2*t,h-2*t,radii.map(v=>Math.max(0,v-t)),smoothing);
   svg+=`<defs><mask id="ring"><path d="${outer}" fill="white"/><path d="${inner}" transform="translate(${t} ${t})" fill="black"/></mask></defs><path d="${outer}" fill="${stroke.color}" fill-opacity="${stroke.opacity}" mask="url(#ring)"/>`;
  }
  return {svg:svg+'</svg>',width:w,height:h,slice:[Math.max(tl,bl)*2,Math.max(tl,tr)*2,(w-Math.max(tr,br))*2,(h-Math.max(bl,br))*2]};
 }
 return {path,surface};
})();
