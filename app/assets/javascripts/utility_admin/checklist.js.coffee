class CheckList
  constructor: (equal)->
    @selected = []
    @equal = equal || (a, b) -> a == b
    this

  add: (selected, equal) ->
    equal = @equal unless equal
    push_flag = true
    for _t in @selected
      push_flag = false if equal(_t, selected)
    @selected.push(selected) if push_flag

  remove: (selected, equal) ->
    equal = @equal unless equal

    _selecteds = []
    for _t in @selected
      _selecteds.push _selecteds unless equal(_t, selected)
    @selected = _selecteds


window.CheckList = CheckList