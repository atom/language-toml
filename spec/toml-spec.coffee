describe "TOML grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-toml")

    runs ->
      grammar = atom.grammars.grammarForScopeName('source.toml')

  it "parses the grammar", ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe "source.toml"

  it "tokenizes comments", ->
    {tokens} = grammar.tokenizeLine("# I am a comment")
    expect(tokens[0]).toEqual value: "#", scopes: ["source.toml", "comment.line.number-sign.toml", "punctuation.definition.comment.toml"]
    expect(tokens[1]).toEqual value: " I am a comment", scopes: ["source.toml", "comment.line.number-sign.toml"]

    {tokens} = grammar.tokenizeLine("# = I am also a comment!")
    expect(tokens[0]).toEqual value: "#", scopes: ["source.toml", "comment.line.number-sign.toml", "punctuation.definition.comment.toml"]
    expect(tokens[1]).toEqual value: " = I am also a comment!", scopes: ["source.toml", "comment.line.number-sign.toml"]

    {tokens} = grammar.tokenizeLine("#Nope = still a comment")
    expect(tokens[0]).toEqual value: "#", scopes: ["source.toml", "comment.line.number-sign.toml", "punctuation.definition.comment.toml"]
    expect(tokens[1]).toEqual value: "Nope = still a comment", scopes: ["source.toml", "comment.line.number-sign.toml"]

    {tokens} = grammar.tokenizeLine(" #Whitespace = tricky")
    expect(tokens[1]).toEqual value: "#", scopes: ["source.toml", "comment.line.number-sign.toml", "punctuation.definition.comment.toml"]
    expect(tokens[2]).toEqual value: "Whitespace = tricky", scopes: ["source.toml", "comment.line.number-sign.toml"]

  it "tokenizes strings", ->
    {tokens} = grammar.tokenizeLine('"I am a string"')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: 'I am a string', scopes: ["source.toml", "string.quoted.double.toml"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]

    {tokens} = grammar.tokenizeLine('"I\'m \\n escaped"')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "I'm ", scopes: ["source.toml", "string.quoted.double.toml"]
    expect(tokens[2]).toEqual value: "\\n", scopes: ["source.toml", "string.quoted.double.toml", "constant.character.escape.toml"]
    expect(tokens[3]).toEqual value: " escaped", scopes: ["source.toml", "string.quoted.double.toml"]
    expect(tokens[4]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]

    {tokens} = grammar.tokenizeLine("'I am not \\n escaped'")
    expect(tokens[0]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: 'I am not \\n escaped', scopes: ["source.toml", "string.quoted.single.toml"]
    expect(tokens[2]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.end.toml"]

    {tokens} = grammar.tokenizeLine('"Equal sign ahead = no problem"')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: 'Equal sign ahead = no problem', scopes: ["source.toml", "string.quoted.double.toml"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]

  it "tokenizes multiline strings", ->
    lines = grammar.tokenizeLines '''
      """
      I am a\\
      string
      """
    '''
    expect(lines[0][0]).toEqual value: '"""', scopes: ["source.toml", "string.quoted.double.block.toml", "punctuation.definition.string.begin.toml"]
    expect(lines[1][0]).toEqual value: 'I am a', scopes: ["source.toml", "string.quoted.double.block.toml"]
    expect(lines[1][1]).toEqual value: '\\', scopes: ["source.toml", "string.quoted.double.block.toml", "constant.character.escape.toml"]
    expect(lines[2][0]).toEqual value: 'string', scopes: ["source.toml", "string.quoted.double.block.toml"]
    expect(lines[3][0]).toEqual value: '"""', scopes: ["source.toml", "string.quoted.double.block.toml", "punctuation.definition.string.end.toml"]

    lines = grammar.tokenizeLines """
      '''
      I am a\\
      string
      '''
    """
    expect(lines[0][0]).toEqual value: "'''", scopes: ["source.toml", "string.quoted.single.block.toml", "punctuation.definition.string.begin.toml"]
    expect(lines[1][0]).toEqual value: 'I am a\\', scopes: ["source.toml", "string.quoted.single.block.toml"]
    expect(lines[2][0]).toEqual value: 'string', scopes: ["source.toml", "string.quoted.single.block.toml"]
    expect(lines[3][0]).toEqual value: "'''", scopes: ["source.toml", "string.quoted.single.block.toml", "punctuation.definition.string.end.toml"]

  it "tokenizes booleans", ->
    {tokens} = grammar.tokenizeLine("true")
    expect(tokens[0]).toEqual value: "true", scopes: ["source.toml", "constant.language.boolean.true.toml"]

    {tokens} = grammar.tokenizeLine("false")
    expect(tokens[0]).toEqual value: "false", scopes: ["source.toml", "constant.language.boolean.false.toml"]

  it "tokenizes integers", ->
    for int in ["+99", "42", "0", "-17", "1_000", "1_2_3_4_5"]
      {tokens} = grammar.tokenizeLine(int)
      expect(tokens[0]).toEqual value: int, scopes: ["source.toml", "constant.numeric.toml"]

  it "tokenizes floats", ->
    for float in ["+1.0", "3.1415", "-0.01", "5e+22", "1e6", "-2E-2", "6.626e-34", "6.626e-34", "9_224_617.445_991_228_313", "1e1_000"]
      {tokens} = grammar.tokenizeLine(float)
      expect(tokens[0]).toEqual value: float, scopes: ["source.toml", "constant.numeric.toml"]

  it "tokenizes dates", ->
    {tokens} = grammar.tokenizeLine("1979-05-27T07:32:00Z")
    expect(tokens[0]).toEqual value: "1979-05-27", scopes: ["source.toml", "constant.numeric.date.toml"]
    expect(tokens[1]).toEqual value: "T", scopes: ["source.toml", "constant.numeric.date.toml", "keyword.other.time.toml"]
    expect(tokens[2]).toEqual value: "07:32:00", scopes: ["source.toml", "constant.numeric.date.toml"]
    expect(tokens[3]).toEqual value: "Z", scopes: ["source.toml", "constant.numeric.date.toml", "keyword.other.offset.toml"]

    {tokens} = grammar.tokenizeLine("1979-05-27T00:32:00.999999-07:00")
    expect(tokens[0]).toEqual value: "1979-05-27", scopes: ["source.toml", "constant.numeric.date.toml"]
    expect(tokens[1]).toEqual value: "T", scopes: ["source.toml", "constant.numeric.date.toml", "keyword.other.time.toml"]
    expect(tokens[2]).toEqual value: "00:32:00.999999", scopes: ["source.toml", "constant.numeric.date.toml"]
    expect(tokens[3]).toEqual value: "-", scopes: ["source.toml", "constant.numeric.date.toml", "keyword.other.offset.toml"]
    expect(tokens[4]).toEqual value: "07:00", scopes: ["source.toml", "constant.numeric.date.toml"]

  it "tokenizes tables", ->
    {tokens} = grammar.tokenizeLine("[table]")
    expect(tokens[0]).toEqual value: "[", scopes: ["source.toml", "entity.name.section.table.toml", "punctuation.definition.table.begin.toml"]
    expect(tokens[1]).toEqual value: "table", scopes: ["source.toml", "entity.name.section.table.toml"]
    expect(tokens[2]).toEqual value: "]", scopes: ["source.toml", "entity.name.section.table.toml", "punctuation.definition.table.end.toml"]

    {tokens} = grammar.tokenizeLine("  [table]")
    expect(tokens[0]).toEqual value: "  ", scopes: ["source.toml"]
    expect(tokens[1]).toEqual value: "[", scopes: ["source.toml", "entity.name.section.table.toml", "punctuation.definition.table.begin.toml"]
    # and so on

  it "tokenizes table arrays", ->
    {tokens} = grammar.tokenizeLine("[[table]]")
    expect(tokens[0]).toEqual value: "[[", scopes: ["source.toml", "entity.name.section.table.array.toml", "punctuation.definition.table.array.begin.toml"]
    expect(tokens[1]).toEqual value: "table", scopes: ["source.toml", "entity.name.section.table.array.toml"]
    expect(tokens[2]).toEqual value: "]]", scopes: ["source.toml", "entity.name.section.table.array.toml", "punctuation.definition.table.array.end.toml"]

  it "tokenizes keys", ->
    {tokens} = grammar.tokenizeLine("key =")
    expect(tokens[0]).toEqual value: "key", scopes: ["source.toml", "variable.other.key.toml"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[2]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine("1key_-34 =")
    expect(tokens[0]).toEqual value: "1key_-34", scopes: ["source.toml", "variable.other.key.toml"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[2]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine("ʎǝʞ =")
    expect(tokens[0]).toEqual value: "ʎǝʞ =", scopes: ["source.toml"]

    {tokens} = grammar.tokenizeLine("  =")
    expect(tokens[0]).toEqual value: "  =", scopes: ["source.toml"]

  it "tokenizes quoted keys", ->
    {tokens} = grammar.tokenizeLine("'key' =")
    expect(tokens[0]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "key", scopes: ["source.toml", "string.quoted.single.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine("'ʎǝʞ' =")
    expect(tokens[0]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "ʎǝʞ", scopes: ["source.toml", "string.quoted.single.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine("'key with spaces' =")
    expect(tokens[0]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "key with spaces", scopes: ["source.toml", "string.quoted.single.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine("'' =")
    expect(tokens[0]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "'", scopes: ["source.toml", "string.quoted.single.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[3]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine('"key" =')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "key", scopes: ["source.toml", "string.quoted.double.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine('"ʎǝʞ" =')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "ʎǝʞ", scopes: ["source.toml", "string.quoted.double.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine('"key with spaces" =')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: "key with spaces", scopes: ["source.toml", "string.quoted.double.toml", "variable.other.key.toml"]
    expect(tokens[2]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[4]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

    {tokens} = grammar.tokenizeLine('"" =')
    expect(tokens[0]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.begin.toml"]
    expect(tokens[1]).toEqual value: '"', scopes: ["source.toml", "string.quoted.double.toml", "punctuation.definition.string.end.toml"]
    expect(tokens[2]).toEqual value: " ", scopes: ["source.toml"]
    expect(tokens[3]).toEqual value: "=", scopes: ["source.toml", "keyword.operator.assignment.toml"]

  describe "firstLineMatch", ->
    it "recognises Emacs modelines", ->
      valid = """
        #-*- TOML -*-
        #-*- mode: toml -*-
        /* -*-toml-*- */
        // -*- TOML -*-
        /* -*- mode:TOML -*- */
        // -*- font:bar;mode:TOML -*-
        // -*- font:bar;mode:TOML;foo:bar; -*-
        // -*-font:mode;mode:TOML-*-
        // -*- foo:bar mode: toml bar:baz -*-
        " -*-foo:bar;mode:toml;bar:foo-*- ";
        " -*-font-mode:foo;mode:toml;foo-bar:quux-*-"
        "-*-font:x;foo:bar; mode : TOML; bar:foo;foooooo:baaaaar;fo:ba;-*-";
        "-*- font:x;foo : bar ; mode : TOML ; bar : foo ; foooooo:baaaaar;fo:ba-*-";
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        /* --*toml-*- */
        /* -*-- TOML -*-
        /* -*- -- TOML -*-
        /* -*- toml -;- -*-
        // -*- ATOML -*-
        // -*- TOML; -*-
        // -*- toml-stuff -*-
        /* -*- model:toml -*-
        /* -*- indent-mode:toml -*-
        // -*- font:mode;TOML -*-
        // -*- mode: -*- TOML
        // -*- mode: tomg-toml -*-
        // -*-font:mode;mode:toml--*-
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()

    it "recognises Vim modelines", ->
      valid = """
        vim: se filetype=toml:
        # vim: se ft=toml:
        # vim: set ft=TOML:
        # vim: set filetype=TOML:
        # vim: ft=TOML
        # vim: syntax=TOML
        # vim: se syntax=toml:
        # ex: syntax=TOML
        # vim:ft=toml
        # vim600: ft=toml
        # vim>600: set ft=toml:
        # vi:noai:sw=3 ts=6 ft=TOML
        # vi::::::::::noai:::::::::::: ft=TOML
        # vim:ts=4:sts=4:sw=4:noexpandtab:ft=TOML
        # vi:: noai : : : : sw   =3 ts   =6 ft  =ToML
        # vim: ts=4: pi sts=4: ft=TOML: noexpandtab: sw=4:
        # vim: ts=4 sts=4: ft=toml noexpandtab:
        # vim:noexpandtab sts=4 ft=toml ts=4
        # vim:noexpandtab:ft=toml
        # vim:ts=4:sts=4 ft=toml:noexpandtab:\x20
        # vim:noexpandtab titlestring=hi\|there\\\\ ft=toml ts=4
      """
      for line in valid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).not.toBeNull()

      invalid = """
        ex: se filetype=toml:
        _vi: se filetype=TOML:
         vi: se filetype=TOML
        # vim set ft=toml
        # vim: soft=toml
        # vim: clean-syntax=toml:
        # vim set ft=toml:
        # vim: setft=TOML:
        # vim: se ft=toml backupdir=tmp
        # vim: set ft=toml set cmdheight=1
        # vim:noexpandtab sts:4 ft:TOML ts:4
        # vim:noexpandtab titlestring=hi\\|there\\ ft=TOML ts=4
        # vim:noexpandtab titlestring=hi\\|there\\\\\\ ft=TOML ts=4
        # vim:ft=coffee ft2=TOML
      """
      for line in invalid.split /\n/
        expect(grammar.firstLineRegex.scanner.findNextMatchSync(line)).toBeNull()
