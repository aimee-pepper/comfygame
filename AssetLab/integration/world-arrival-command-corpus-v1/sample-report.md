# World Arrival command corpus v1

- Cases: 85
- Maximum command count: 1365 (seed-matrix/00, seed-matrix/01, seed-matrix/02, seed-matrix/03, seed-matrix/04, seed-matrix/05, seed-matrix/06, seed-matrix/07, seed-matrix/08, seed-matrix/09, seed-matrix/10, seed-matrix/11, seed-matrix/12, seed-matrix/13, seed-matrix/14, seed-matrix/15, seed-matrix/16, seed-matrix/17, seed-matrix/18, seed-matrix/19, seed-matrix/20, seed-matrix/21, seed-matrix/22, seed-matrix/23, seed-matrix/24, seed-matrix/25, seed-matrix/26, seed-matrix/27, seed-matrix/28, seed-matrix/29, seed-matrix/30, seed-matrix/31)
- Seeded material widths exercised: 1, 2, 3, 4
- Seeded Stone Hollow path jitters exercised: -1, 0, 1, 2
- Unique seeded placement signatures: 32
- Canonical body: d2783de992abb183a9d9372d60af67251b9e43d14830806bcbabc7781a9448fc

## Scope-contained counterfactuals

- flora: accepted/starter_open_meadow → accepted/near_flora; changed flora
- illumination: accepted/starter_open_meadow → scope-counterfactual/illumination; changed illumination
- suspended: accepted/starter_open_meadow → scope-counterfactual/suspended; changed suspended
- precipitation: accepted/starter_open_meadow → scope-counterfactual/precipitation; changed precipitation
- resource-band: accepted/starter_open_meadow → scope-counterfactual/resource-band; changed none
- title-only: accepted/starter_open_meadow → scope-counterfactual/title-only; changed none

## Ordered command sample

Case: accepted/starter_open_meadow
```json
[
  {
    "op": "rect-v1",
    "x": 2,
    "y": 2,
    "width": 156,
    "height": 96,
    "rgba": [
      216,
      189,
      130,
      255
    ],
    "scope": "frame",
    "sourceOrder": 0
  },
  {
    "op": "rect-v1",
    "x": 6,
    "y": 6,
    "width": 148,
    "height": 88,
    "rgba": [
      23,
      22,
      20,
      255
    ],
    "scope": "frame",
    "sourceOrder": 1
  },
  {
    "op": "rect-v1",
    "x": 10,
    "y": 10,
    "width": 140,
    "height": 80,
    "rgba": [
      37,
      59,
      73,
      255
    ],
    "scope": "frame",
    "sourceOrder": 2
  },
  {
    "op": "rect-v1",
    "x": 10,
    "y": 10,
    "width": 140,
    "height": 34,
    "rgba": [
      48,
      55,
      70,
      255
    ],
    "scope": "illumination",
    "sourceOrder": 3
  },
  {
    "op": "rect-v1",
    "x": 59,
    "y": 25,
    "width": 8,
    "height": 2,
    "rgba": [
      103,
      84,
      58,
      255
    ],
    "scope": "ground",
    "sourceOrder": 4
  },
  {
    "op": "rect-v1",
    "x": 51,
    "y": 27,
    "width": 8,
    "height": 2,
    "rgba": [
      103,
      84,
      58,
      255
    ],
    "scope": "ground",
    "sourceOrder": 5
  },
  {
    "op": "rect-v1",
    "x": 59,
    "y": 27,
    "width": 6,
    "height": 2,
    "rgba": [
      173,
      140,
      87,
      255
    ],
    "scope": "ground",
    "sourceOrder": 6
  },
  {
    "op": "rect-v1",
    "x": 65,
    "y": 27,
    "width": 2,
    "height": 2,
    "rgba": [
      103,
      84,
      58,
      255
    ],
    "scope": "ground",
    "sourceOrder": 7
  }
]
```
