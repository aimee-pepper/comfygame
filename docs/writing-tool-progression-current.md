# Writing tools and colored-ink progression — current

**Status:** settled progression; implementation-ready naming, capability and migration boundary.  
**Owner:** Isolde's Scriptorium / Penmanship.  
**Supersedes:** the charcoal → pencil → fountain-pen ladder and any statement that Ash ink is the
new-game writing tool.

## The three tools

| Order | Tool | Page hand | Footprint | Ink relationship |
|---:|---|---|---|---|
| 1 | **Rough charcoal** | crude | 4–6 cells, irregular | Starting tool; dry charcoal only; color is unspecified/open |
| 2 | **Brush** | plain | 2–3 cells, controlled shapes | First liquid-ink tool; always supports unlimited Ash ink and supports mixed colored inks once Ink Mixing is learned |
| 3 | **Fountain pen** | refined | 1 cell | Final writing tool; supports the same Ash/mixed inks at maximum spatial precision |

The alphabet does not change. Better tools preserve the same rune identity at a smaller physical
footprint. The Brush replaces the Pencil completely in current fiction, UI and content: it is both
the middle precision step and the point at which ink becomes physically meaningful.

## Penmanship graph

The Scriptorium graph uses these exact relationships:

```text
Rough charcoal (starting capability; not a purchased node)
        |
      Brush
      / | \
     /  |  \
Ink Mixing   Compound Assembly   Chaining     (tier-1 siblings)
                                      |
                                Ruling frame / tier 2
                                      |
                                Fountain pen
```

- **Brush** is Isolde's first purchased hand and the prerequisite for Ink Mixing.
- **Ink Mixing** is a direct adjacent unlock from Brush. It remains unavailable until Brush is
  owned and the Scriptorium is tier 1; it is not placed behind Compound Assembly or Chaining.
- Compound Assembly and Chaining remain independent siblings. Learning color does not tax semantic
  compression, and learning compression does not grant color.
- **Fountain pen** is the terminal hand. It still requires Chaining and Scriptorium tier 2, but does
  not require Ink Mixing: a player may obtain maximum spatial precision while continuing to write
  with open-color Ash ink.

The table/foundation nodes that raise Scriptorium tier remain construction gates, not additional
writing tools. Exact costs remain playtest tuning and should be re-costed as a Brush recipe without
changing the opening continuation envelope merely to preserve the old Pencil ingredients.

## Medium and page behavior

- Rough-charcoal marks cannot carry a mixed liquid-ink recipe. The Desk disables **Apply mixed ink**
  for such a mark and explains **Requires a Brush or Fountain pen**.
- Once Brush is owned, new Brush marks use unlimited **Ash ink** by default. Ash is dark on the page
  but stores no color instruction, so bind-time color remains fully open.
- Ink Mixing adds CMY+Depth recipes and saved mixtures. It does not unlock Brush and is never usable
  through Rough charcoal.
- Fountain-pen marks use Ash/open or any owned prepared mixture exactly as Brush marks do; the pen's
  advantage is footprint precision, not a second color gamut.
- Rewriting a charcoal mark with Brush or Fountain pen is an explicit page edit. It may change the
  stored footprint/placement and therefore must pass normal collision validation; applying ink never
  silently shrinks, moves or reflows an old mark.
- A page may mix all three hands. Only Brush/Fountain source marks can consume mixed-ink applications.

## Stable identity migration

Do not preserve a live internal “pencil” name beneath a Brush UI:

- new stable research ID: `pen_brush`;
- `pen_pencil` is one-way decode/migration input only and grants `pen_brush` ownership once;
- every current prerequisite referring to `pen_pencil` migrates to `pen_brush`;
- saved `Hand.plain` and already placed plain-hand shapes remain byte-compatible and merely display
  **Brush**; page geometry does not migrate;
- the current diary reward/reference to `pen_pencil` migrates to `pen_brush`; any persisted legacy
  page/reward ID receives an explicit alias rather than appearing as a second Pencil teaching; and
- release content/string validation rejects player-facing **Pencil**, **A pencil**, and “sketchy
  pencil” outside historical/archive documents.

## Acceptance

1. Fresh save: Rough charcoal only; no Ink well and no mixed recipe can be attached.
2. Brush purchase: 2–3-cell writing and Ash/open ink become available; Ink Mixing is visible as the
   adjacent locked/available node according to Scriptorium tier.
3. Ink Mixing purchase: CMY+Depth works on Brush marks but rejects Rough-charcoal marks without
   spending pigment or mutating the page.
4. Fountain pen: 1-cell Ash and mixed-color marks work; owning the pen without Ink Mixing does not
   accidentally grant the mixer.
5. Old save with `pen_pencil`: one Brush ownership, no duplicate point/cost, unchanged placed page
   geometry and correct dependent-node ownership after relaunch.
6. Desk, Library/History, diary, DEBUG and VoiceOver use current tool names consistently.

