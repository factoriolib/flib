--[[
  NEW GUI MODULE
  This module uses a component-based architecture, allowing ease of re-use and better GUI state management and updating
  than the old GUI module provided. While the original module is great for making static GUIs, it is not so great when
  you need to constantly mutate and update the GUI.

  The main goals of this module are as follows:
  - Divide GUIs into "components"
    - Each component has the following properties / methods:
      - `create()` - create the component
      - `init()` - returns the initial state for the component
      - `destroy()` - clean up any external data used by the component. the component's GUI, state, handlers, and
        updaters will be cleaned up automatically
      - `updaters` - a table of unique updater functions associated with this component
        - updaters are stored globally in gui2, and can be called from anywhere in the codebase using `gui.dispatch()`
        - default parameters:
          - `player_index`: the index of the player for whom this updater is being called
          - `component_data`: the component's data table, consisting of `elems`, `state`, and `filters`
          - `event_data` (optional): passed in when the updater is called from a GUI event
        - additional parameters will be passed to the updater function
    - The GUI's table in `global` is not directly accessed - each component's state is provided in the updater or
      handler callback
]]