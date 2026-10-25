import {test} from 'node:test';
import assert from 'node:assert/strict';
import {makeGrid} from './grid-fixture.mjs';
test('Penpot grid metadata preserves flow, padding and gaps without opting in',()=>{
 for(const dir of ['row','column']){
  const fixture=makeGrid(dir),doc=fixture.export(),g=doc.design.grid;
  assert.equal(g.dir,dir);assert.equal(g.columns,3);assert.equal(g.rows,2);
  assert.deepEqual([...g.padding],[12,12,12,12]);assert.equal(g.columnGap,8);assert.equal(g.rowGap,10);
  assert.equal(g.unsupportedCells,false);assert.equal(doc.design.layout,undefined);
  assert.match(doc.warnings.join(' '),/measured positions by default/);
  assert.equal(doc.design.children[0].id,'slot-4','paint order is unchanged');
 }
});
test('grid spans, margins, absolute children and dynamic sizing are marked unsafe',()=>{
 for(const extra of [{layoutCell:{columnSpan:2}},{layoutCell:{rowSpan:2}},{layoutChild:{absolute:true}},{layoutChild:{topMargin:4}},{layoutChild:{minWidth:20}},{layoutChild:{horizontalSizing:'fill'}}]){
  const fixture=makeGrid();Object.assign(fixture.root.children[0],extra);
  assert.equal(fixture.export().design.grid.unsupportedCells,true);
 }
});
