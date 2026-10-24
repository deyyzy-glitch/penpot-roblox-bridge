// Run in Penpot plugin context. Creates only one dedicated test board.
const b=penpot.createBoard();b.name='Penpot Roblox • Test Dashboard';b.resize(800,560);b.x=2000;b.y=0;b.fills=[{fillColor:'#101827',fillOpacity:1}];b.clipContent=true;
storage.p2rFixture=b;
function box(parent,name,x,y,w,h,fill,radius=0){const s=penpot.createRectangle();parent.appendChild(s);s.name=name;s.resize(w,h);s.x=parent.x+x;s.y=parent.y+y;s.fills=[{fillColor:fill,fillOpacity:1}];s.borderRadius=radius;return s}
function text(parent,name,value,x,y,w,h,size,color,align='left'){const s=penpot.createText(value);parent.appendChild(s);s.name=name;const font=penpot.fonts.findByName('Arial');if(font)font.applyToText(s);s.fontSize=String(size);s.fontWeight='400';s.lineHeight='1.2';s.align=align;s.verticalAlign='center';s.fills=[{fillColor:color,fillOpacity:1}];s.resize(w,h);s.x=parent.x+x;s.y=parent.y+y;return s}
text(b,'Brand','ORBIT / CONTROL',28,22,370,36,25,'#F3F6FF');
text(b,'Status','SYSTEM ONLINE',550,28,220,26,14,'#67E8BC','right');
const panel=penpot.createBoard();b.appendChild(panel);panel.name='Overview Panel';panel.resize(744,190);panel.x=b.x+28;panel.y=b.y+82;panel.borderRadius=16;panel.fills=[{fillColorGradient:{type:'linear',startX:0,startY:.5,endX:1,endY:.5,width:1,stops:[{color:'#273C75',offset:0,opacity:1},{color:'#185A6B',offset:1,opacity:1}]}}];panel.strokes=[{strokeColor:'#4B698A',strokeWidth:2,strokeAlignment:'inner',strokeStyle:'solid',strokeOpacity:1}];
text(panel,'Overview Title','Your next mission starts here.',24,24,650,38,26,'#FFFFFF');
text(panel,'Overview Copy','Design in Penpot. Build with native Roblox UI.',24,72,680,26,17,'#C7D8ED');
const cta=box(panel,'Launch [button]',24,118,170,44,'#778FFF',10);text(panel,'Launch Caption','Launch mission',34,124,150,30,16,'#FFFFFF','center');
storage.p2rCta=cta;
const secondary=box(panel,'Details [button]',208,118,140,44,'#20354B',10);secondary.strokes=[{strokeColor:'#6B849D',strokeWidth:1,strokeAlignment:'inner',strokeStyle:'solid'}];text(panel,'Details Caption','View details',218,124,120,30,16,'#E5EFFF','center');
const row=penpot.createBoard();b.appendChild(row);row.name='Statistics Row';row.resize(744,154);row.x=b.x+28;row.y=b.y+296;row.fills=[];
const flex=row.addFlexLayout();flex.dir='row';flex.wrap='nowrap';flex.columnGap=18;flex.rowGap=18;flex.alignItems='start';flex.justifyContent='start';flex.topPadding=0;flex.leftPadding=0;flex.bottomPadding=0;flex.rightPadding=0;
for(let i=0;i<3;i++){const card=penpot.createBoard();card.name=['Missions','Credits','Rank'][i]+' Card';card.resize(236,154);card.fills=[{fillColor:'#1D2A3D'}];card.borderRadius=12;row.appendChild(card);text(card,'Metric Label',['MISSIONS','CREDITS','RANK'][i],18,18,190,24,13,'#9BB1CC');text(card,'Metric Value',['24','8,450','Explorer'][i],18,55,198,48,30,'#F3F6FF');}
const icon=penpot.createEllipse();b.appendChild(icon);icon.name='Native Status Icon';icon.resize(12,12);icon.x=b.x+30;icon.y=b.y+484;icon.fills=[{fillColor:'#67E8BC'}];
text(b,'Footer','All systems ready',52,476,400,28,15,'#A8BBD3');
const path=penpot.createPath();path.name='Star Vector Icon';path.d='M12 0 L15 8 L24 9 L17 15 L19 24 L12 19 L5 24 L7 15 L0 9 L9 8 Z';path.fills=[{fillColor:'#FFD56B'}];b.appendChild(path);path.x=b.x+736;path.y=b.y+478;
storage.p2rVector=path;
penpot.selection=[b];penpot.viewport.zoomIntoView([b]);
return {id:b.id,font:penpot.fonts.findByName('Arial')?.name,children:b.children.length};
