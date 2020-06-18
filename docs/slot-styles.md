FLib includes several "slot styles" for your use and convenience:

![](https://raw.githubusercontent.com/factoriolib/flib/a4eb6f47828cad98b63d8bed78b9af6106891c45/docs/assets/slot-style-examples.png)

There are three categories of style, from top to bottom: `slot`, `slot_button`, and `standalone_slot_button`. From left to right, the colors are `default`, `red`, `yellow`, `green`, `cyan`, `blue`, `purple`, and `pink`.

The styles are formatted as `flib_CATEGORY_COLOR`. For example, if I want a pink standalone slot button (bottom-right on the preview image), I would use `flib_standalone_slot_button_pink`.

Each and every style also has a `selected` variant, which uses the hovered graphics as default. This is intended to let a user "select" a button, and to let the mod visually distinguish it from other buttons around it. To use these styles, replace `flib_` with `flib_selected_` in the style you wish to use (e.g. `flib_selected_slot_button_green`).

Modifying these styles in any way will modify them for all mods using them. Therefore, unless you know what you are doing and are doing it intentionally, _DO NOT MODIFY THESE STYLES!_ Instead, create your own, new styles using these as parents, then modify those new styles as you wish.
