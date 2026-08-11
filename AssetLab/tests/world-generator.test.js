import assert from "node:assert/strict";
import { floraDefaults,floraPresets,normalizeFlora,floraCommands,terrainTemplateCatalogue,worldGradeFromReadings,normalizeTerrain,transitionedTerrainCommands,liftedTerrainProfile,liftedTerrainSprite,liftedSurfaceLayerCommands,sampleWorld,sampleMultiSpeciesWorld,floraSpeciesSet,adjacencyFor,isPassableGround,crackOverlayCommands,groundTypes,groundRuleFacts } from "../src/world-generator.js";
import { commandBounds,hash } from "../src/generator.js";
for(const [profile,size] of [["world",16],["detail",48]]){const commands=floraCommands(floraDefaults,profile);const b=commandBounds(commands);assert.ok(b.minX>=0&&b.minY>=0&&b.maxX<=size&&b.maxY<=size);assert.deepEqual(commands,floraCommands(floraDefaults,profile));}
const active={...floraDefaults,traits:{...floraDefaults.traits,defenceType:"active",defence:90}};
assert.equal(Object.keys(floraPresets).length,7,"all live flora identity regions need authoring presets");
const floraRegionHashes=new Set(Object.entries(floraPresets).map(([name,traits],index)=>hash(floraCommands(normalizeFlora({...floraDefaults,logicalID:name,speciesSeed:700+index,traits}),"world"))));
assert.equal(floraRegionHashes.size,7,"live flora regions need distinct native world silhouettes");
assert.notEqual(hash(floraCommands(active,"detail")),hash(floraCommands(active,"hostile")),"triggered hostile pose must be separate from neutral detail");
const specimenLike={...floraDefaults,specimenSeed:999};
assert.equal(hash(floraCommands(specimenLike,"world")),hash(floraCommands(floraDefaults,"world")),"flora species art ignores per-placement jitter");
const tissue=normalizeFlora({...floraDefaults,traits:{...floraDefaults.traits,woody:99,fibrous:99,fleshy:99}}).traits;
assert.equal(tissue.woody+tissue.fibrous+tissue.fleshy,100);
const transitions=new Set();for(let adjacency=0;adjacency<16;adjacency++)transitions.add(hash(transitionedTerrainCommands({adjacency,ground:"water",revealed:true})));
assert.equal(transitions.size,16,"all water adjacency masks need distinct command output");
assert.notEqual(hash(transitionedTerrainCommands({ground:"water",revealed:true})),hash(transitionedTerrainCommands({ground:"water",revealed:false})));
assert.notEqual(hash(transitionedTerrainCommands({ground:"water",cracking:false})),hash(transitionedTerrainCommands({ground:"water",cracking:true})));
assert.notEqual(hash(transitionedTerrainCommands({ground:"water"})),hash(transitionedTerrainCommands({ground:"deepWater"})),"ordinary and deep water need distinct grammar");
assert.equal(transitionedTerrainCommands({ground:"water",revealed:false}).length,1,"fog must contain literally nothing");
assert.notEqual(hash(transitionedTerrainCommands({ground:"soil",elevation:0})),hash(transitionedTerrainCommands({ground:"soil",elevation:2})),"elevation needs redundant shape grammar");
for(const ground of groundTypes){
  const levels=[0,1,2,3].map(elevation=>transitionedTerrainCommands({ground,elevation,adjacency:15,terrainSeedUInt32:404}));
  if(ground==="chasm"){
    assert.equal(new Set(levels.map(hash)).size,1,"chasm is missing ground and must suppress elevation cues");
    continue;
  }
  assert.equal(new Set(levels.map(hash)).size,4,`${ground} elevation levels must remain shape-distinct`);
  const baseLength=levels[0].length;
  for(let elevation=1;elevation<=3;elevation++){
    const cues=levels[elevation].slice(baseLength);
    assert.equal(cues.length,elevation*2,`${ground} elevation ${elevation} must add one paired contour cue per level`);
    assert.equal(cues.every(command=>command.x>0&&command.y>0&&command.x+command.w<16&&command.y+command.h<16),true,`${ground} elevation cues must remain inset and never become a tile border`);
    assert.doesNotMatch(JSON.stringify(cues),/#21170f|#b28a56|#6b4b2d/i,`${ground} elevation must derive color from its own terrain palette`);
  }
}
for(const ground of ["stone","soil","sand","ash","rubble","mud"]){
  for(let elevation=0;elevation<=3;elevation++){
    const sprite=liftedTerrainSprite({ground,elevation,terrainSeedUInt32:404},{southExposureLevels:elevation});
    assert.equal(sprite.width,16);assert.equal(sprite.height,19);assert.deepEqual(sprite.pivot,{x:8,y:18});
    assert.equal(sprite.surfaceOffsetY,3-elevation);assert.equal(sprite.commands[0].y,3-elevation,"complete top plane must translate intact");
    const wall=sprite.commands.slice(transitionedTerrainCommands({ground,elevation:0,terrainSeedUInt32:404}).length);
    assert.equal(wall.every(command=>command.color!=="#21170f"&&command.color!=="#b28a56"&&command.color!=="#6b4b2d"),true,"lifted walls never use generic dirt/stake colors");
  }
}
for(const elevation of [0,1,2,3])assert.equal(liftedTerrainSprite({ground:"chasm",elevation},{southExposureLevels:0}).elevation,0,"chasm cannot rise");
for(const ground of ["water","deepWater","ice","growth","groundcover"])assert.equal(liftedTerrainSprite({ground,elevation:3},{southExposureLevels:0}).elevation,0,`${ground} needs explicit resolved substrate/shelf/basin facts before elevation`);
const equalTerrace=liftedTerrainSprite({ground:"soil",elevation:2,terrainSeedUInt32:404},{southExposureLevels:0}),dropTerrace=liftedTerrainSprite({ground:"soil",elevation:2,terrainSeedUInt32:404},{southExposureLevels:2});
assert.equal(equalTerrace.commands.length,transitionedTerrainCommands({ground:"soil",elevation:0,terrainSeedUInt32:404}).length,"equal heights must not create a wall seam");
assert.ok(dropTerrace.commands.length>equalTerrace.commands.length,"only a positive southward height delta exposes a wall");
const routeOverlay=[{op:"rect",x:1,y:6,w:14,h:4,color:"#e1c06f"}],liftedRoute=liftedSurfaceLayerCommands(routeOverlay,dropTerrace,"route-action-target");assert.equal(liftedRoute[0].y,routeOverlay[0].y+dropTerrace.surfaceOffsetY,"route/content/actor layers must move with the top plane");
assert.deepEqual(liftedTerrainProfile,{profile:"terrain-lifted-1.0.0",width:16,height:19,pivot:{x:8,y:18},logicalFootprint:{width:16,height:16},maxElevation:3,riserPixelsPerLevel:1});
for(const elevation of [1,2,3]){for(const state of [{revealed:false},{revealed:true,crumbled:true}]){const sprite=liftedTerrainSprite({ground:"soil",elevation,...state},{southExposureLevels:0});assert.equal(sprite.elevation,0);assert.equal(sprite.surfaceOffsetY,3);assert.equal(sprite.commands.some(command=>command.y>=19),false,"hidden/crumbled sprites stay inside the base footprint");}}
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:2}),/missing-south-exposure-levels/);
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:2},{}),/missing-south-exposure-levels/);
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:2},{southExposureLevels:0,extra:true}),/unknown-lifted-exposure-field/);
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:1},{southExposureLevels:2}),/inconsistent-south-exposure-levels/);
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:3,revealed:false},{southExposureLevels:1}),/inconsistent-south-exposure-levels/);
assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:2},{southExposureLevels:-1}),/invalid-south-exposure-levels/);assert.throws(()=>liftedTerrainSprite({ground:"soil",elevation:2},{southExposureLevels:4}),/invalid-south-exposure-levels/);assert.throws(()=>liftedSurfaceLayerCommands(routeOverlay,dropTerrace,"floating-alert-badge"),/unsupported-lifted-layer/);
for(const ground of groundTypes){
  const joined=transitionedTerrainCommands({ground,adjacency:15,terrainSeedUInt32:404});
  const isolated=transitionedTerrainCommands({ground,adjacency:0,terrainSeedUInt32:404});
  const ownsEdges=["water","deepWater","ice","chasm"].includes(ground);
  assert.equal(isolated.length-joined.length,ownsEdges?4:0,`${ground} adjacency must ${ownsEdges?"own four isolated":"not create any"} perimeter edges`);
}
assert.equal(groundTypes.length,12,"AssetLab must track every live GroundType");
assert.equal(new Set(groundTypes.map((ground,index)=>hash(transitionedTerrainCommands({ground,speciesSeed:404+index})))).size,12,"every live ground needs distinct command grammar");
assert.equal(isPassableGround("water"),true);assert.equal(isPassableGround("deepWater"),false);assert.equal(isPassableGround("chasm"),false);
assert.equal(groundRuleFacts.water.passable,true);assert.equal(groundRuleFacts.ice.passable,true);
assert.equal(groundRuleFacts.mud.slow,true);assert.equal(groundRuleFacts.mud.blocksSight,false);
assert.equal(groundRuleFacts.growth.slow,true);assert.equal(groundRuleFacts.growth.blocksSight,true);
assert.equal(groundRuleFacts.rubble.slow,false);assert.equal(groundRuleFacts.rubble.blocksSight,true);
assert.equal(groundRuleFacts.groundcover.overgrown,true);assert.equal(groundRuleFacts.groundcover.blocksSight,false);
assert.notEqual(hash(transitionedTerrainCommands({ground:"stone",crumbled:false})),hash(transitionedTerrainCommands({ground:"stone",crumbled:true})),"crumbled/gone is distinct from intact terrain");
for(const ground of groundTypes){assert.equal(terrainTemplateCatalogue[ground].length,4,`${ground} needs four bounded feature templates`);const variants=[0,1,2,3].map(featureVariant=>hash(transitionedTerrainCommands({ground,featureVariant,speciesSeed:404})));assert.equal(new Set(variants).size,4,`${ground} feature templates must differ`);}const neutral=transitionedTerrainCommands({ground:"soil",featureVariant:2,worldGrade:{red:0,green:0,blue:0,value:0}}),warm=transitionedTerrainCommands({ground:"soil",featureVariant:2,worldGrade:{red:16,green:4,blue:-10,value:3}});assert.notEqual(hash(neutral),hash(warm),"world grade must recolor stable geometry");assert.deepEqual(neutral.map(({x,y,w,h})=>({x,y,w,h})),warm.map(({x,y,w,h})=>({x,y,w,h})),"world grade must not mutate terrain affordance geometry");
const forbiddenTemplateSemantics=/(crack|fracture|root|reed|track|ember|scorch|dune|shelf|cold)/i;for(const [ground,names] of Object.entries(terrainTemplateCatalogue))for(const name of names)assert.doesNotMatch(name,forbiddenTemplateSemantics,`${ground}.${name} invents a live state/content fact`);
assert.deepEqual(worldGradeFromReadings({thermalMidpoint:50,availableWater:50,vitalityPeak:50,lightMidpoint:50,substratePeak:50}),{red:0,green:0,blue:0,value:0});assert.deepEqual(worldGradeFromReadings({thermalMidpoint:90,availableWater:20,vitalityPeak:25,lightMidpoint:80,substratePeak:75}),{red:23,green:-16,blue:-18,value:12});assert.deepEqual(worldGradeFromReadings({thermalMidpoint:10,availableWater:90,vitalityPeak:85,lightMidpoint:20,substratePeak:30}),{red:-22,green:22,blue:22,value:-11});
const terrainSeedContract=normalizeTerrain({terrainSeedUInt32:77});assert.equal(terrainSeedContract.terrainSeedUInt32,77);assert.equal("speciesSeed" in terrainSeedContract,false);assert.deepEqual(transitionedTerrainCommands({ground:"soil",terrainSeedUInt32:77}),transitionedTerrainCommands({ground:"soil",speciesSeed:77}),"deprecated proof alias must remain pixel-compatible");
const world=sampleWorld(floraDefaults);assert.equal(world.cells.length,81);for(const cell of world.cells)assert.ok(adjacencyFor(world,cell)>=0&&adjacencyFor(world,cell)<=15);
const adjacencyFixture={cells:[{x:0,y:0,ground:"soil"},{x:1,y:0,ground:"soil"},{x:0,y:1,ground:"sand"}]};assert.equal(adjacencyFor(adjacencyFixture,adjacencyFixture.cells[0]),2,"only the exact same-ground east neighbor sets a bit; different ground and out-of-bounds remain clear");
for(let count=1;count<=4;count++){const species=floraSpeciesSet(floraDefaults,count),multi=sampleMultiSpeciesWorld(floraDefaults,count);assert.equal(species.length,count);assert.equal(multi.species.length,count);assert.equal(new Set(species.map(item=>hash(floraCommands(item,"world")))).size,count,"each integrated species needs a stable distinct world sprite");assert.ok(multi.cells.filter(cell=>cell.flora).every(cell=>cell.floraSpecies>=0&&cell.floraSpecies<count));}
const fourSpecies=sampleMultiSpeciesWorld(floraDefaults,4),placements=fourSpecies.cells.filter(cell=>cell.flora),repeat=placements.filter(cell=>cell.floraSpecies===0);assert.ok(repeat.length>=2,"review fixture needs a repeated species");assert.equal(hash(floraCommands(fourSpecies.species[0],"world")),hash(floraCommands(fourSpecies.species[repeat[1].floraSpecies],"world")),"repeat pixels must remain identical across patch context");assert.ok(placements.some(cell=>cell.ground==="groundcover"));assert.ok(placements.some(cell=>cell.ground==="growth"));assert.ok(placements.some(cell=>world.cells.some(route=>route.route&&Math.abs(route.x-cell.x)+Math.abs(route.y-cell.y)===1)),"flora must sit beside the route");
assert.ok(world.cells.some(cell=>cell.ground==="deepWater"));
assert.ok(world.cells.some(cell=>cell.route));
assert.equal(world.cells.filter(cell=>cell.party).length,1);
assert.equal(world.cells.filter(cell=>cell.portal).length,1);
assert.equal(world.cells.filter(cell=>cell.site).length,1);
const route=world.cells.filter(cell=>cell.route);
assert.ok(route.every(cell=>cell.revealed&&isPassableGround(cell.ground)),"demo route must derive from revealed passability");
assert.ok(new Set(route.map(cell=>cell.x)).size>1&&new Set(route.map(cell=>cell.y)).size>1,"demo route must include a turn along the water contour");
assert.ok(world.cells.filter(cell=>cell.portal||cell.site||cell.party).every(cell=>cell.route),"collision symbols should share the route fixture");
assert.ok(crackOverlayCommands().length>0,"cracks need a dedicated last-pass overlay");
const patchSignatures=new Set(["spreading","clustered","solitary"].map(habit=>{const result=sampleWorld({...floraDefaults,traits:{...floraDefaults.traits,habit}});return hash(result.cells.map(cell=>({x:cell.x,y:cell.y,flora:cell.flora})));}));
assert.equal(patchSignatures.size,3,"habits must produce distinct spatial topology");
console.log("Asset Lab world/flora tests passed.");
