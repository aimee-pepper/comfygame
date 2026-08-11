import {canonicalJSON,hash} from "./generator.js";
import {rasterHash} from "./regression.js";
import {groundTypes,liftedTerrainProfile,liftedTerrainSprite} from "./world-generator.js";

export const liftedTerrainPipelineVersions=Object.freeze({contractVersion:1,terrainAdapterVersion:"lifted-terrain-adapter-1.0.0",terrainGrammarVersion:"terrain-lifted-1.0.0",worldGradeAdapterVersion:"world-grade-1.0.0",renderProfileVersion:"terrain-16x19-bottom-anchored-1.0.0"});
const diagnostic=(code,path,message)=>({code,path,message}),exactVersions=value=>canonicalJSON(value)===canonicalJSON(liftedTerrainPipelineVersions);
function rejectUnknown(value,allowed,path,issues){if(!value||typeof value!=="object"||Array.isArray(value))return;for(const key of Object.keys(value))if(!allowed.includes(key))issues.push(diagnostic("unknown-field",path?`${path}.${key}`:key,"field is outside the closed lifted-terrain contract"));}
function validUInt32(value){return Number.isInteger(value)&&value>=0&&value<=0xffffffff;}
function validGrade(value){return value&&Number.isInteger(value.red)&&value.red>=-32&&value.red<=32&&Number.isInteger(value.green)&&value.green>=-32&&value.green<=32&&Number.isInteger(value.blue)&&value.blue>=-32&&value.blue<=32&&Number.isInteger(value.value)&&value.value>=-20&&value.value<=20;}
export function adaptLiftedTerrainRequest(request){
  const issues=[];if(!request||typeof request!=="object"||Array.isArray(request))return{ok:false,diagnostics:[diagnostic("invalid-request","$","request must be an object")]};
  rejectUnknown(request,["pipelineVersions","ground","revealed","crumbled","cracking","elevation","adjacencyNESW","terrainSeedUInt32","featureVariant","worldGrade","southExposureLevels"],"",issues);
  rejectUnknown(request.worldGrade,["red","green","blue","value"],"worldGrade",issues);
  if(!exactVersions(request.pipelineVersions))issues.push(diagnostic("pipeline-version-mismatch","pipelineVersions","exact immutable lifted-terrain tuple required"));
  if(!groundTypes.includes(request.ground))issues.push(diagnostic("invalid-ground","ground","expected an exact live GroundType raw value"));
  for(const key of ["revealed","crumbled","cracking"])if(typeof request[key]!=="boolean")issues.push(diagnostic("invalid-boolean",key,"explicit Boolean required"));
  if(!Number.isInteger(request.elevation)||request.elevation<0||request.elevation>3)issues.push(diagnostic("invalid-elevation","elevation","expected integer 0...3"));
  if(!Number.isInteger(request.adjacencyNESW)||request.adjacencyNESW<0||request.adjacencyNESW>15)issues.push(diagnostic("invalid-adjacency","adjacencyNESW","expected N=1 E=2 S=4 W=8 mask 0...15"));
  if(!validUInt32(request.terrainSeedUInt32))issues.push(diagnostic("invalid-terrain-seed","terrainSeedUInt32","native must supply a persisted-derived UInt32; conformance seed 404 is not a runtime default"));
  if(!Number.isInteger(request.featureVariant)||request.featureVariant<0||request.featureVariant>3)issues.push(diagnostic("invalid-feature-variant","featureVariant","expected stable placement variant 0...3"));
  if(!validGrade(request.worldGrade))issues.push(diagnostic("invalid-world-grade","worldGrade","signed RGB must be -32...32 and value -20...20 integers"));
  const forcedZero=request.revealed===false||request.crumbled===true||["water","deepWater","chasm","ice","growth","groundcover"].includes(request.ground),resolvedElevation=forcedZero?0:request.elevation;
  if(!Number.isInteger(request.southExposureLevels)||request.southExposureLevels<0||request.southExposureLevels>3)issues.push(diagnostic("invalid-south-exposure","southExposureLevels","required resolved south exposure integer 0...3"));
  else if(request.southExposureLevels>resolvedElevation)issues.push(diagnostic("inconsistent-south-exposure","southExposureLevels","cannot exceed resolved center elevation; forced-zero states require zero"));
  if(issues.length)return{ok:false,diagnostics:issues};
  const sprite=liftedTerrainSprite({ground:request.ground,revealed:request.revealed,crumbled:request.crumbled,cracking:request.cracking,elevation:request.elevation,adjacency:request.adjacencyNESW,terrainSeedUInt32:request.terrainSeedUInt32,featureVariant:request.featureVariant,worldGrade:request.worldGrade},{southExposureLevels:request.southExposureLevels});
  return{ok:true,pipelineVersions:liftedTerrainPipelineVersions,profile:liftedTerrainProfile,commands:sprite.commands,resolvedElevation:sprite.elevation,surfaceOffsetY:sprite.surfaceOffsetY,canonicalRequestHash:hash(canonicalJSON(request)),rectangleHash:hash(canonicalJSON(sprite.commands)),pixelHash:rasterHash(sprite.commands,liftedTerrainProfile.width,liftedTerrainProfile.height),hashAlgorithm:"AssetLab hash v1 fixture hashes; export packager must emit canonical SHA-256 and decoded RGBA SHA-256",diagnostics:[]};
}
