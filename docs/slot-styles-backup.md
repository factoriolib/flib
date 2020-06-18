FLib includes several "slot styles" for your use and convenience:

![](https://raw.githubusercontent.com/factoriolib/flib/a4eb6f47828cad98b63d8bed78b9af6106891c45/docs/assets/slot-style-examples.png)

The following table states each style, respectively:

|                        | default                             | red                             | yellow                             | green                             | cyan                             | blue                             | purple                             | pink                             |
| ---------------------- | ----------------------------------- | ------------------------------- | ---------------------------------- | --------------------------------- | -------------------------------- | -------------------------------- | ---------------------------------- | -------------------------------- |
| slot                   | flib_slot_default                   | flib_slot_red                   | flib_slot_yellow                   | flib_slot_green                   | flib_slot_cyan                   | flib_slot_blue                   | flib_slot_purple                   | flib_slot_pink                   |
| slot_button            | flib_slot_button_default            | flib_slot_button_red            | flib_slot_button_yellow            | flib_slot_button_green            | flib_slot_button_cyan            | flib_slot_button_blue            | flib_slot_button_purple            | flib_slot_button_pink            |
| standalone_slot_button | flib_standalone_slot_button_default | flib_standalone_slot_button_red | flib_standalone_slot_button_yellow | flib_standalone_slot_button_green | flib_standalone_slot_button_cyan | flib_standalone_slot_button_blue | flib_standalone_slot_button_purple | flib_standalone_slot_button_pink |

Each and every style also has a `selected` variant, which uses the hovered graphics as default. This is intended to let a user "select" a button, and to let the mod visually distinguish it from other buttons around it. To use these styles, replace `flib_` with `flib_selected_` in the style you wish to use.

Modifying these styles in any way will modify them for all mods using them. Therefore, unless you know what you are doing and are doing it intentionally, _DO NOT MODIFY THESE STYLES!_ Instead, create your own, new styles using these as parents, then modify those new styles as you wish.
