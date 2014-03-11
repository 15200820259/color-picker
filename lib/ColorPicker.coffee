# ----------------------------------------------------------------------------
#  ColorPicker
# ----------------------------------------------------------------------------

        ConditionalContextMenu = require './conditional-contextmenu'

    # -------------------------------------
    #  Regex matchers
    # -------------------------------------
        REGEXES = [
            # Matches HEX + A: eg
            # rgba(#fff, 0.3) and rgba(#000000, .8)
            { type: 'hexa', regex: /(rgba\(((\#[a-f0-9]{6}|\#[a-f0-9]{3}))\s*,\s*(0|1|0*\.\d+)\))/ig }

            # Matches RGB + A: eg.
            # rgba(0, 99, 199, 0.3)
            { type: 'rgba', regex: /(rgba\(((([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])))\s*,\s*(0|1|0*\.\d+)\))/ig }

            # Matches RGB: eg.
            # rgb(0, 99, 199)
            { type: 'rgb', regex: /(rgb\(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\s*,\s*([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\))/ig }

            # Matches HEX:
            # eg. #000 and #ffffff
            { type: 'hex', regex: /(\#[a-f0-9]{6}|\#[a-f0-9]{3})/ig }
        ]

    # -------------------------------------
    #  Public functionality
    # -------------------------------------
        module.exports =
            view: null
            match: null

            activate: ->
                atom.workspaceView.command "color-picker:open", => @open()

                ConditionalContextMenu.item {
                    label: 'Color picker'
                    command: 'color-picker:open',
                }, => return true if @match = @getMatchAtCursor()

                ColorPickerView = require './ColorPicker-view'
                @view = new ColorPickerView

            deactivate: -> @view.destroy()

            # Get a match at the current cursor position
            getMatchAtCursor: ->
                _editor = atom.workspace.getActiveEditor()
                return unless _editor

                _line = _editor.getCursor().getCurrentBufferLine()
                _cursorBuffer = _editor.getCursorBufferPosition()
                _cursorRow = _cursorBuffer.row
                _cursorColumn = _cursorBuffer.column

                return @matchAtPosition _cursorColumn, (@matchesOnLine _line, _cursorRow)

            # Match the current line against the regexes
            # @String line
            # @Number cursorRow
            matchesOnLine: (line, cursorRow) ->
                _filteredMatches = []; for { type, regex } in REGEXES
                    continue unless _matches = line.match regex

                    for match in _matches
                        # Skip if the match has “been used” already
                        continue if (_index = line.indexOf match) is -1

                        _filteredMatches.push
                            color: match
                            type: type
                            index: _index
                            end: _index + match.length
                            row: cursorRow

                        # Make sure the indices are correct by removing
                        # the instances from the string after use
                        line = line.replace match, (Array match.length + 1).join ' '
                return unless _filteredMatches.length > 0

                return _filteredMatches

            # Get a single match on a position based on a match array
            # as seen in matchesOnLine
            # @Number column
            # @Array matches
            matchAtPosition: (column, matches) ->
                return unless column and matches

                _match = do -> for match in matches
                    if match.index <= column and match.end >= column
                        return match
                return _match

            open: ->
                return unless @match

                @view.open()
                @view.storage.selectedColor = @match
                @view.inputColor @match
                @view.selectColor()
