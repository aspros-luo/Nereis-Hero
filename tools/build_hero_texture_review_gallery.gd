extends SceneTree
## Build a local HTML gallery for reviewing texture candidates by ID and source coordinates.
## Run after split_hero_texture_atlas.gd:
## godot --headless --path . --script tools/build_hero_texture_review_gallery.gd
## Writes user://hero_texture_parts/index.html; source assets are not modified.

const OUTPUT_DIR := "user://hero_texture_parts"
const MANIFEST_PATH := "user://hero_texture_parts/manifest.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if manifest_file == null:
		push_error("Cannot open manifest. Run split_hero_texture_atlas.gd first: " + ProjectSettings.globalize_path(MANIFEST_PATH))
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()
	if not parsed is Dictionary:
		push_error("Invalid manifest JSON.")
		quit(1)
		return

	var components: Array = parsed.get("components", [])
	var grid_data: Dictionary = parsed.get("grid_candidates", {})
	var grids: Array = grid_data.get("items", [])
	var records: Array[Dictionary] = []
	for item in components:
		var bounds: Dictionary = item.get("bounds", {})
		var crop_bounds: Dictionary = item.get("crop_bounds_with_padding", {})
		records.append({
			"id": str(item.get("id", "")),
			"kind": "component",
			"file": str(item.get("file", "")),
			"x": int(bounds.get("x", 0)),
			"y": int(bounds.get("y", 0)),
			"width": int(bounds.get("width", 0)),
			"height": int(bounds.get("height", 0)),
			"area": int(item.get("area_pixels", 0)),
			"crop_x": int(crop_bounds.get("x", 0)),
			"crop_y": int(crop_bounds.get("y", 0)),
			"crop_width": int(crop_bounds.get("width", 0)),
			"crop_height": int(crop_bounds.get("height", 0))
		})
	for item in grids:
		var bounds: Dictionary = item.get("bounds", {})
		records.append({
			"id": str(item.get("id", "")),
			"kind": "grid",
			"file": str(item.get("file", "")),
			"x": int(bounds.get("x", 0)),
			"y": int(bounds.get("y", 0)),
			"width": int(bounds.get("width", 0)),
			"height": int(bounds.get("height", 0)),
			"area": 0,
			"crop_x": int(bounds.get("x", 0)),
			"crop_y": int(bounds.get("y", 0)),
			"crop_width": int(bounds.get("width", 0)),
			"crop_height": int(bounds.get("height", 0))
		})

	var html := _html_document(records, components.size(), grids.size())
	var output_path := OUTPUT_DIR.path_join("index.html")
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	if output == null:
		push_error("Cannot write gallery: " + ProjectSettings.globalize_path(output_path))
		quit(1)
		return
	output.store_string(html)
	output.close()
	print("Texture review gallery created.")
	print("Components: %d; grid crops: %d" % [components.size(), grids.size()])
	print("Open in browser: " + ProjectSettings.globalize_path(output_path))
	quit(0)

func _html_document(records: Array[Dictionary], component_count: int, grid_count: int) -> String:
	var data_json := JSON.stringify(records)
	var html := """<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Nereis Hero 纹理候选审查</title>
<style>
:root{color-scheme:dark;font:14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
body{margin:0;background:#17191d;color:#e9edf2}header{position:sticky;top:0;background:#202329;padding:14px 18px;z-index:2;border-bottom:1px solid #393d45}
h1{font-size:20px;margin:0 0 8px}.controls{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
input,select,button{background:#30343c;color:#f5f5f5;border:1px solid #555b66;border-radius:6px;padding:8px}
#stats{color:#b9c0ca;margin:8px 0 0}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:10px;padding:14px}
.card{min-width:0;background:#24272e;border:1px solid #414650;border-radius:8px;overflow:hidden}.thumb{height:130px;display:flex;align-items:center;justify-content:center;background-color:#353941;background-image:linear-gradient(45deg,#444 25%,transparent 25%),linear-gradient(-45deg,#444 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#444 75%),linear-gradient(-45deg,transparent 75%,#444 75%);background-size:16px 16px;background-position:0 0,0 8px,8px -8px,-8px 0}
.thumb img{max-width:100%;max-height:100%;object-fit:contain;image-rendering:auto}.meta{padding:8px}.id{font-weight:700;font-size:14px}.coords{font-size:12px;color:#b9c0ca;overflow-wrap:anywhere}.actions{display:flex;gap:6px;margin-top:6px}.actions button{font-size:11px;padding:5px}
footer{padding:16px;text-align:center;color:#b9c0ca}
</style></head><body>
<header><h1>Nereis Hero · 纹理候选审查</h1>
<div class="controls"><select id="kind"><option value="component">组件候选</option><option value="grid">网格候选</option><option value="all">全部候选</option></select>
<input id="search" placeholder="按编号搜索，如 C001 / G0001">
<select id="sort"><option value="id">按编号</option><option value="area">按像素面积（组件）</option><option value="position">按原图位置</option></select>
<button id="prev">上一页</button><span id="page"></span><button id="next">下一页</button></div>
<div id="stats"></div></header><main class="grid" id="cards"></main><footer>候选仅按几何区域提取；请勿仅凭编号自动认定为身体部件。源图坐标以左上角为原点。</footer>
<script>
const records = __DATA__;
const PAGE_SIZE=100;let page=0;
const $=id=>document.getElementById(id);
function filtered(){let kind=$('kind').value,q=$('search').value.trim().toLowerCase(),sort=$('sort').value;
let a=records.filter(r=>(kind==='all'||r.kind===kind)&&(!q||r.id.toLowerCase().includes(q)));
if(sort==='area')a.sort((x,y)=>y.area-x.area||x.id.localeCompare(y.id));
else if(sort==='position')a.sort((x,y)=>x.y-y.y||x.x-y.x);
else a.sort((x,y)=>x.id.localeCompare(y.id,undefined,{numeric:true}));
return a}
function render(){let a=filtered(),pages=Math.max(1,Math.ceil(a.length/PAGE_SIZE));page=Math.max(0,Math.min(page,pages-1));let shown=a.slice(page*PAGE_SIZE,(page+1)*PAGE_SIZE);
$('cards').innerHTML=shown.map(r=>'<article class="card"><div class="thumb"><img loading="lazy" src="'+r.file+'" alt="'+r.id+'"></div><div class="meta"><div class="id">'+r.id+'</div><div class="coords">源图：('+r.x+', '+r.y+') · '+r.width+'×'+r.height+'</div>'+(r.kind==='component'?'<div class="coords">像素面积：'+r.area+' · 裁剪：('+r.crop_x+', '+r.crop_y+') '+r.crop_width+'×'+r.crop_height+'</div>':'')+'<div class="actions"><button onclick="navigator.clipboard.writeText(\''+r.id+'\')">复制编号</button><button onclick="window.open(\''+r.file+'\',\'_blank\')">打开原切片</button></div></div></article>').join('');
$('page').textContent=(page+1)+' / '+pages;$('stats').textContent='当前筛选 '+a.length+' 个；总计组件 '+__COMPONENTS__+' 个、网格 '+__GRIDS__+' 个。';
$('prev').disabled=page===0;$('next').disabled=page>=pages-1}
['kind','sort'].forEach(id=>$(id).addEventListener('change',()=>{page=0;render()}));$('search').addEventListener('input',()=>{page=0;render()});$('prev').onclick=()=>{page--;render()};$('next').onclick=()=>{page++;render()};render();
</script></body></html>"""
	html = html.replace("__DATA__", data_json)
	html = html.replace("__COMPONENTS__", str(component_count))
	html = html.replace("__GRIDS__", str(grid_count))
	return html
