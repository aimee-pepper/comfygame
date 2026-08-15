#!/usr/bin/env python3
"""Freeze the reviewed mob-material and gear-family source atlases into native-size sprites."""

from __future__ import annotations

import argparse
import hashlib
import json
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "AssetLab/source/mob-gear-sprites-v1"
OUTPUT = ROOT / "AssetLab/integration/mob-gear-sprites-v1"

MOB_MATERIALS = [
    "plate", "quill", "pelt", "down", "hide", "chitin", "fang", "tusk",
    "claw", "bone", "ichor", "timber", "fibre", "pulp", "toxin", "reagent",
]

GEAR_FAMILIES = [
    "pointed_blade", "cutting_blade", "hand_maul", "long_spear", "longbow", "sling",
    "throwing_set", "fitted_point", "fitted_edge", "fitted_maul", "fitted_polearm", "wild_hook",
    "buckler", "tower_shield", "padded_cap", "enclosed_helm", "supple_coat", "rigid_guard",
    "working_gloves", "gauntlets", "working_boots", "greaves", "field_pick", "keepsake",
]

# Found gear uses an authored family silhouette plus a structural material palette. Treatments and
# quality remain metadata/overlays; they never replace the central object identity.
WORLD_MATERIALS = {
    "rubble":       {"level": 1, "roles": ["structural"], "family": "sling",          "palette": [0x171516, 0x403A38, 0x68605C, 0x948A83, 0xC5BBB2]},
    "clay":         {"level": 1, "roles": ["structural"], "family": "buckler",        "palette": [0x24130F, 0x643521, 0x9B5837, 0xC77C4D, 0xE4AC76]},
    "ore":          {"level": 2, "roles": ["structural"], "family": "cutting_blade", "palette": [0x17171A, 0x3B3D45, 0x686B74, 0xA2A6AE, 0xE0E0DC]},
    "copper":       {"level": 2, "roles": ["structural"], "family": "buckler",        "palette": [0x2B140C, 0x6E321D, 0xA9552C, 0xD17B43, 0xF0B67B]},
    "silver":       {"level": 3, "roles": ["structural", "fitting"], "family": "enclosed_helm", "palette": [0x20212A, 0x555C70, 0x858FA5, 0xBDC7D8, 0xF1F4F7]},
    "gold":         {"level": 3, "roles": ["fitting", "accessory"], "family": "keepsake", "palette": [0x3A2108, 0x8A570D, 0xC98D1D, 0xF0C34D, 0xFFF0A1]},
    "quartz":       {"level": 2, "roles": ["structural", "fitting"], "family": "long_spear", "palette": [0x30252D, 0x725E73, 0xAA92A5, 0xDCC8D7, 0xFFF2F6]},
    "obsidian":     {"level": 3, "roles": ["structural"], "family": "fitted_edge",   "palette": [0x09080E, 0x201B31, 0x44395D, 0x745B82, 0xB28FB6]},
    "salt":         {"level": 1, "roles": ["treatment", "accessory"], "family": "keepsake", "palette": [0x4A4442, 0x938984, 0xC7BCB5, 0xECE5DC, 0xFFFDF6]},
    "sulfur":       {"level": 2, "roles": ["treatment", "fitting"], "family": "hand_maul", "palette": [0x33200A, 0x79600E, 0xB89A17, 0xE0C533, 0xFFF080]},
    "mercury":      {"level": 3, "roles": ["treatment", "fitting"], "family": "working_gloves", "palette": [0x25272C, 0x626873, 0x929AA5, 0xC9D0D7, 0xF6FAFC]},
    "adamant":      {"level": 4, "roles": ["structural"], "family": "rigid_guard",    "palette": [0x111A18, 0x24493F, 0x377B68, 0x62AF91, 0xB2E4C7]},
    "fiber":        {"level": 1, "roles": ["structural", "binding"], "family": "sling", "palette": [0x231A10, 0x604628, 0x8D6D3E, 0xB69562, 0xDFC993]},
    "timber":       {"level": 1, "roles": ["structural"], "family": "longbow",         "palette": [0x28150C, 0x60351D, 0x8D5630, 0xB97E4A, 0xDEA96E]},
    "pulp":         {"level": 1, "roles": ["padding", "component"], "family": "padded_cap", "palette": [0x3B342C, 0x766B5B, 0xA89C85, 0xD2C7AD, 0xEFE7D3]},
    "resin":        {"level": 1, "roles": ["binding", "treatment"], "family": "working_boots", "palette": [0x321A09, 0x70400F, 0xA56518, 0xD08C2B, 0xF2BB55]},
    "toxin":        {"level": 2, "roles": ["treatment"], "family": "fitted_edge",      "palette": [0x13200F, 0x34532A, 0x578447, 0x83B967, 0xC2E69B]},
    "spore":        {"level": 2, "roles": ["treatment", "padding"], "family": "supple_coat", "palette": [0x24172C, 0x563967, 0x805891, 0xAE83BC, 0xDDC3E2]},
    "reagent":      {"level": 2, "roles": ["treatment", "fitting"], "family": "field_pick", "palette": [0x14272C, 0x28606C, 0x3D91A0, 0x70C0C6, 0xBCE9E5]},
    "ichor":        {"level": 2, "roles": ["treatment"], "family": "wild_hook",        "palette": [0x29101E, 0x651B42, 0x9B2D65, 0xCF4D89, 0xF498BD]},
    "rift_glass":   {"level": 4, "roles": ["structural", "fitting"], "family": "fitted_point", "palette": [0x12182D, 0x293B72, 0x4668AF, 0x72A3E5, 0xC5E5FF]},
    "essence_raw":  {"level": 4, "roles": ["catalyst", "accessory"], "family": "keepsake", "palette": [0x281B3C, 0x5D3E83, 0x8D66B7, 0xC19AE0, 0xF1DFFF]},
    "mote":         {"level": 4, "roles": ["realityCurrency", "accessory"], "family": "keepsake", "palette": [0x2D1734, 0x70417A, 0xA962B0, 0xDC91DD, 0xFFD4FA]},
}

RESOURCE_GEAR = {
    "rubble_sling": "rubble", "fired_clay_guard": "clay", "ironwork_blade": "ore",
    "copper_buckler": "copper", "silvered_helm": "silver", "golden_keepsake": "gold",
    "quartz_point": "quartz", "obsidian_edge": "obsidian", "saltward_pendant": "salt",
    "sulfurous_maul": "sulfur", "mercurial_gloves": "mercury", "adamant_cuirass": "adamant",
    "woven_sling": "fiber", "timber_longbow": "timber", "pressed_pulp_cap": "pulp",
    "resinbound_boots": "resin", "toxin_edge": "toxin", "sporeward_coat": "spore",
    "reagent_field_pick": "reagent", "ichor_hook": "ichor", "riftglass_rapier": "rift_glass",
    "raw_essence_pendant": "essence_raw", "mote_compass": "mote",
}

# Existing catalogue gear keeps its authored object family while gaining an exact structural
# material profile. This closes the visual consumer for every live gear drop; it does not alter
# stats, rarity, drop weights, or crafting recipes.
LEGACY_GEAR = {
    "blade_chipped": ("ore", "pointed_blade"), "blade_keen": ("copper", "cutting_blade"),
    "ripping_hook": ("obsidian", "wild_hook"), "the_long_grievance": ("adamant", "fitted_edge"),
    "bone_awl": ("quartz", "pointed_blade"), "raking_edge": ("ore", "fitted_edge"),
    "blade_binders": ("silver", "cutting_blade"), "hairsplitter": ("rift_glass", "fitted_point"),
    "field_maul": ("timber", "hand_maul"), "banded_mace": ("copper", "fitted_maul"),
    "anvilfall": ("ore", "fitted_maul"), "the_settled_argument": ("adamant", "hand_maul"),
    "long_pick": ("timber", "long_spear"), "warded_spear": ("quartz", "fitted_polearm"),
    "parting_needle": ("silver", "long_spear"), "the_kept_distance": ("rift_glass", "fitted_polearm"),
    "split_board": ("timber", "buckler"), "banded_buckler": ("copper", "buckler"),
    "tower_guard": ("ore", "tower_shield"), "the_unarguable": ("adamant", "tower_shield"),
    "padded_cap": ("pulp", "padded_cap"), "ridged_helm": ("copper", "enclosed_helm"),
    "visored_casque": ("silver", "enclosed_helm"), "crown_of_quiet": ("gold", "enclosed_helm"),
    "guard_padded": ("fiber", "supple_coat"), "guard_banded": ("copper", "rigid_guard"),
    "guard_vault": ("ore", "rigid_guard"), "the_standing_wall": ("adamant", "rigid_guard"),
    "wrapped_hands": ("fiber", "working_gloves"), "studded_gloves": ("copper", "working_gloves"),
    "gauntlets_of_hold": ("ore", "gauntlets"), "the_sure_hands": ("adamant", "gauntlets"),
    "worn_boots": ("resin", "working_boots"), "shod_boots": ("copper", "working_boots"),
    "longstriders": ("silver", "greaves"), "the_unhurried": ("adamant", "greaves"),
    "bent_pick": ("timber", "field_pick"), "balanced_pick": ("copper", "field_pick"),
    "corebreaker": ("ore", "field_pick"), "the_willing_edge": ("adamant", "field_pick"),
    "pressed_leaf": ("pulp", "keepsake"), "cold_compass": ("quartz", "keepsake"),
    "someones_ring": ("gold", "keepsake"), "the_first_page": ("essence_raw", "keepsake"),
    "two_natured_blade": ("rift_glass", "fitted_point"), "long_fang": ("quartz", "long_spear"),
    "ranked_spear": ("ore", "fitted_polearm"), "rimed_edge": ("obsidian", "wild_hook"),
    "living_hook": ("ichor", "wild_hook"), "quiet_knife": ("obsidian", "pointed_blade"),
    "bloodletter": ("toxin", "fitted_edge"), "warded_haft": ("reagent", "fitted_maul"),
}

CATALOGUE_GEAR = {
    **{item_id: (material_id, WORLD_MATERIALS[material_id]["family"])
       for item_id, material_id in RESOURCE_GEAR.items()},
    **LEGACY_GEAR,
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def canonical_json(value: object) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def split_atlas(source: Path, columns: int, rows: int, names: list[str], out: Path) -> list[dict]:
    atlas = Image.open(source).convert("RGBA")
    assert len(names) == columns * rows
    records: list[dict] = []
    for index, name in enumerate(names):
        column, row = index % columns, index // columns
        left = round(column * atlas.width / columns)
        top = round(row * atlas.height / rows)
        right = round((column + 1) * atlas.width / columns)
        bottom = round((row + 1) * atlas.height / rows)
        # Inset past the authored grid line, then fit the opaque object to a stable square canvas.
        cell = atlas.crop((left + 2, top + 2, right - 2, bottom - 2))
        alpha = cell.getchannel("A")
        bounds = alpha.getbbox()
        if bounds is None:
            raise ValueError(f"empty sprite cell: {name}")
        object_image = cell.crop(bounds)
        scale = min(28 / object_image.width, 28 / object_image.height)
        size = (max(1, round(object_image.width * scale)), max(1, round(object_image.height * scale)))
        object_image = object_image.resize(size, Image.Resampling.NEAREST)
        object_image = object_image.quantize(colors=12, method=Image.Quantize.FASTOCTREE).convert("RGBA")
        sprite = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
        sprite.alpha_composite(object_image, ((32 - size[0]) // 2, (32 - size[1]) // 2))
        target = out / f"{name}.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        sprite.save(target, optimize=False, compress_level=9)
        occupied = sum(1 for value in sprite.getchannel("A").getdata() if value > 0)
        if not 40 <= occupied <= 784:
            raise ValueError(f"implausible occupied area for {name}: {occupied}")
        records.append({"id": name, "file": target.name, "sha256": sha256(target),
                        "width": 32, "height": 32, "occupiedPixels": occupied})
    return records


def recolor(source: Path, palette: list[int], target: Path) -> dict:
    image = Image.open(source).convert("RGBA")
    output = Image.new("RGBA", image.size, (0, 0, 0, 0))
    source_pixels = image.load()
    target_pixels = output.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = source_pixels[x, y]
            if alpha == 0:
                continue
            luminance = (red * 299 + green * 587 + blue * 114) // 1000
            index = min(len(palette) - 1, luminance * len(palette) // 256)
            color = palette[index]
            target_pixels[x, y] = ((color >> 16) & 0xff, (color >> 8) & 0xff, color & 0xff, alpha)
    target.parent.mkdir(parents=True, exist_ok=True)
    output.save(target, optimize=False, compress_level=9)
    occupied = sum(1 for value in output.getchannel("A").getdata() if value > 0)
    return {"file": target.name, "sha256": sha256(target), "width": 32, "height": 32,
            "occupiedPixels": occupied}


def render(destination: Path) -> dict:
    mob = split_atlas(SOURCE / "mob-material-atlas-alpha.png", 4, 4, MOB_MATERIALS,
                      destination / "mob-drops")
    gear = split_atlas(SOURCE / "gear-family-atlas-alpha.png", 6, 4, GEAR_FAMILIES,
                       destination / "gear-families")
    catalogue_gear: list[dict] = []
    for item_id, (material_id, family_id) in CATALOGUE_GEAR.items():
        profile = WORLD_MATERIALS[material_id]
        record = recolor(destination / "gear-families" / f"{family_id}.png",
                         profile["palette"], destination / "catalogue-gear" / f"{item_id}.png")
        catalogue_gear.append({"id": item_id, "materialProfileID": f"world:{material_id}",
                               "visualFamilyID": family_id, "materialLevel": profile["level"],
                               **record})
    manifest = {
        "schemaVersion": 1,
        "packID": "mob-gear-sprites-v1",
        "integrationReady": True,
        "profiles": {
            "mobDropInventory": {"size": [32, 32], "sprites": mob},
            "gearInventory": {"size": [32, 32], "sprites": gear},
            "catalogueGear": {"size": [32, 32], "sprites": catalogue_gear},
        },
        "materialRendering": {
            "geometryAuthority": "gear family sprite",
            "paletteAuthority": "structural material profile",
            "qualityAndLevelDoNotSelectGeometry": True,
            "fallback": "nil",
        },
        "coverage": {
            "mobMaterialKinds": MOB_MATERIALS,
            "gearFamilies": GEAR_FAMILIES,
            "worldResourceMaterialProfiles": [
                {"id": f"world:{material_id}", "materialLevel": profile["level"],
                 "roles": profile["roles"], "visualFamilyID": profile["family"],
                 "paletteRGB": [f"#{value:06x}" for value in profile["palette"]]}
                for material_id, profile in WORLD_MATERIALS.items()
            ],
        },
        "exclusions": [
            "No rarity, quality, level or stat badge is baked into pixels.",
            "No gameplay property is inferred from sprite color.",
            "Quality and stat badges remain separate presentation metadata.",
        ],
    }
    body_hash = hashlib.sha256(canonical_json(manifest)).hexdigest()
    manifest["canonicalBodySHA256"] = body_hash
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        with tempfile.TemporaryDirectory() as directory:
            candidate = Path(directory)
            render(candidate)
            expected = {path.relative_to(OUTPUT): path.read_bytes() for path in OUTPUT.rglob("*") if path.is_file()}
            actual = {path.relative_to(candidate): path.read_bytes() for path in candidate.rglob("*") if path.is_file()}
            if expected != actual:
                missing = sorted(str(path) for path in expected.keys() - actual.keys())
                extra = sorted(str(path) for path in actual.keys() - expected.keys())
                changed = sorted(str(path) for path in expected.keys() & actual.keys()
                                 if expected[path] != actual[path])
                raise SystemExit(f"sprite pack drift; missing={missing}, extra={extra}, changed={changed}")
        print("mob-gear-sprites-v1 is reproducible")
        return
    manifest = render(OUTPUT)
    print(manifest["canonicalBodySHA256"])


if __name__ == "__main__":
    main()
