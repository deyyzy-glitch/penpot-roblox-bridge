/* Shared between the companion plugin and the connected Penpot test harness. */
globalThis.P2R = (() => {
  const version = 1;
  function exportSelection(api, selection = [...api.selection]) {
    if (selection.length !== 1) throw Error('Select exactly one board, component, or group.');
    const root = selection[0];
    if (!['board', 'group'].includes(root.type)) throw Error('Select a board, component board, or group.');
    const warnings = [], assets = [], shapes = new Map();
    const warn = (s, text) => warnings.push(`${s.name} (${s.id}): ${text}`);
    const copy = o => JSON.parse(JSON.stringify(o));
    const num = (v, fallback = 0) => v != null && Number.isFinite(Number(v)) ? Number(v) : fallback;
    let count = 0;
    function visit(s, parent, depth, suppressed=false) {
      if (++count > 5000 || depth > 64) throw Error('Selection exceeds 5000 shapes or 64 levels.');
      shapes.set(s.id, s);
      const rot = num(parent?.rotation) * Math.PI / 180;
      const dx = s.center.x - (parent?.center.x || 0), dy = s.center.y - (parent?.center.y || 0);
      const x = parent ? dx * Math.cos(rot) + dy * Math.sin(rot) + parent.width / 2 - s.width / 2 : 0;
      const y = parent ? -dx * Math.sin(rot) + dy * Math.cos(rot) + parent.height / 2 - s.height / 2 : 0;
      let fills = Array.isArray(s.fills) ? copy(s.fills.map(f => ({
        fillColor:f.fillColor, fillOpacity:f.fillOpacity, fillColorGradient:f.fillColorGradient,
        imageId:f.fillImage?.id
      }))) : [];
      if (s.fills === 'mixed') warn(s, 'Mixed text fills require a raster fallback for exact appearance.');
      const vector = ['path','boolean','svg-raw','image'].includes(s.type) || (s.type === 'ellipse' && Math.abs(s.width-s.height) > 0.1);
      const image = fills.some(f => f.imageId);
      const radii = [s.borderRadiusTopLeft,s.borderRadiusTopRight,s.borderRadiusBottomRight,s.borderRadiusBottomLeft].map(v=>num(v));
      const reasons=[];
      if(fills.length>1)reasons.push('multiple fills');
      if(s.shadows?.some(v=>!v.hidden))reasons.push('shadows');
      if(s.blur||s.backgroundBlur)reasons.push('blur');
      if(s.blendMode&&s.blendMode!=='normal')reasons.push('blend mode');
      if(s.flipX||s.flipY)reasons.push('mirroring');
      if(new Set(radii).size>1)reasons.push('individual corner radii');
      if((s.strokes||[]).length>1||(s.strokes||[]).some(v=>v.strokeColorGradient||(v.strokeStyle&&!['solid','none'].includes(v.strokeStyle))))reasons.push('complex strokes');
      for(const f of fills){const g=f.fillColorGradient;if(g&&(g.type!=='linear'||!((g.startX===0&&g.endX===1&&g.startY===.5&&g.endY===.5)||(g.startY===0&&g.endY===1&&g.startX===.5&&g.endX===.5))))reasons.push('gradient geometry')}
      if(s.type==='text'){
        if(s.fills==='mixed'||[s.fontFamily,s.fontSize,s.fontWeight,s.align,s.fontStyle].includes('mixed'))reasons.push('mixed text styling');
        if(num(s.letterSpacing)||s.textDecoration&&s.textDecoration!=='none'||s.direction==='rtl')reasons.push('text typography');
        if(!['Arial','arial','sourcesanspro','Source Sans Pro','Roboto','roboto','Ubuntu','ubuntu'].includes(s.fontFamily))reasons.push('font fidelity');
        if(s.characters.includes('\n')||s.textBounds.height>num(s.fontSize,16)*1.8)reasons.push('multiline typography');
      }
      const subtree=!!s.children?.length&&(num(s.opacity,1)<1||(s.clipContent&&(reasons.length||new Set(radii).size>1))||(s.blendMode&&s.blendMode!=='normal'));
      if(subtree)reasons.push('composited subtree');
      const raster=!suppressed&&(vector||image||reasons.length>0);
      if (raster) {
        const key = `${api.currentFile.id}:${s.id}`;
        assets.push({key, shapeId:s.id, name:s.name, reason:[vector?'vector':image?'image-fill':null,...reasons].filter(Boolean).join(', '), format:'png', scale:2,skipChildren:!subtree});
        if(reasons.length)warn(s,`Automatic image surface: ${reasons.join(', ')}. Native source objects are retained${subtree?'; descendant visuals are included in this effect surface':''}.`);
      }
      const n = {
        id:s.id, name:s.name, type:s.type, x, y, width:s.width, height:s.height,
        rotation:parent ? num(s.rotation)-num(parent.rotation) : 0,
        opacity:num(s.opacity,1), visible:!s.hidden,
        clip:!!s.clipContent, radius:radii[0] || num(s.borderRadius), fills,
        strokes:copy(s.strokes || []),
        constraints:{horizontal:s.constraintsHorizontal || 'left',vertical:s.constraintsVertical || 'top'},
        assetKey:raster ? `${api.currentFile.id}:${s.id}` : undefined,
        rasterSurface:raster&&!vector&&!image,rasterSubtree:subtree,
        visualSuppressed:suppressed,rasterOpacityBaked:raster,
        button:/\[button\]/i.test(s.name),
        children:[]
      };
      if (s.type === 'text') {
        n.text={value:s.characters,size:num(s.fontSize,16),family:s.fontFamily,weight:num(s.fontWeight,400),
          italic:s.fontStyle === 'italic',align:s.align,verticalAlign:s.verticalAlign,
          lineHeight:num(s.lineHeight,1.2),letterSpacing:num(s.letterSpacing),transform:s.textTransform,
          measuredWidth:s.textBounds.width,measuredHeight:s.textBounds.height};
      }
      if (s.flex) {
        const f=s.flex;
        n.layout={dir:f.dir,wrap:f.wrap,gap:f.dir.startsWith('row')?f.columnGap:f.rowGap,
          align:f.alignItems,justify:f.justifyContent,
          padding:[f.topPadding,f.rightPadding,f.bottomPadding,f.leftPadding]};
        const supported=['row','column'].includes(f.dir) && f.wrap !== 'wrap' &&
          ['start','center','end'].includes(f.alignItems || 'start') && (f.justifyContent || 'start')==='start' &&
          (s.children || []).every(c=>!c.layoutChild?.absolute &&
            !['auto','fill'].includes(c.layoutChild?.horizontalSizing) && !['auto','fill'].includes(c.layoutChild?.verticalSizing) &&
            !['topMargin','rightMargin','bottomMargin','leftMargin'].some(k=>num(c.layoutChild?.[k])!==0));
        n.layout.native= supported&&!raster;
        if (!supported) warn(s, 'Complex flex is baked to measured desktop positions; resize constraints remain available.');
      }
      if (s.grid) warn(s, 'Grid is baked to measured desktop positions.');
      n.children=(s.children || []).map(c=>visit(c,s,depth+1,suppressed||subtree));
      return n;
    }
    const document={format:'penpot-roblox',version,source:{fileId:api.currentFile.id,pageId:api.currentPage.id,rootId:root.id},
      design:visit(root,null,0),warnings,assets,assetMap:{},fontMap:{}};
    return {document,shapes};
  }
  async function exportAssets(bundle) {
    const result=[];
    for(const a of bundle.document.assets) {
      const shape=bundle.shapes.get(a.shapeId);
      const svg=await shape.export({type:'svg',skipChildren:a.skipChildren});
      const header=Array.from(svg.slice(0,1500),v=>String.fromCharCode(v)).join('');
      const match=header.match(/viewBox="([^"]+)"/);if(!match)throw Error('Export has no raster bounds: '+a.name);
      const viewBox=match[1].trim().split(/\s+/).map(Number),scale=Math.min(2,1024/viewBox[2],1024/viewBox[3]);
      const bytes=await shape.export({type:'png',scale,skipChildren:a.skipChildren});
      result.push({...a,viewBox,shapeWidth:shape.width,shapeHeight:shape.height,rotation:shape.rotation||0,bytes:Array.from(bytes)});
    }
    return result;
  }
  return {exportSelection,exportAssets};
})();
