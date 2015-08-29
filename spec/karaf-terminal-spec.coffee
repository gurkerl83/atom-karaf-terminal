KarafTerminal = require '../lib/karaf-terminal'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "KarafTerminal", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('atom-karaf-terminal')

  describe "when the karaf-terminal:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.atom-karaf-terminal')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'karaf-terminal:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.atom-karaf-terminal')).toExist()

        atomKarafTerminalElement = workspaceElement.querySelector('.atom-karaf-terminal')
        expect(atomKarafTerminalElement).toExist()

        atomKarafTerminalPanel = atom.workspace.panelForItem(atomKarafTerminalElement)
        expect(atomKarafTerminalPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'karaf-terminal:toggle'
        expect(atomKarafTerminalPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.atom-karaf-terminal')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'karaf-terminal:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        atomKarafTerminalElement = workspaceElement.querySelector('.atom-karaf-terminal')
        expect(atomKarafTerminalElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'karaf-terminal:toggle'
        expect(atomKarafTerminalElement).not.toBeVisible()
