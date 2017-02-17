require(["jasmineEnv"], function (jasmineEnv) {
  var setupTests = function () {
    "use strict";

    describe("Given a DeleteMultipleSubItems model", function () {
      var component = new Sitecore.Definitions.Models.DeleteMultipleSubItems();

      describe("when I create a DeleteMultipleSubItems model", function () {
        it("it should have a 'isVisible' property that determines if the DeleteMultipleSubItems component is visible or not", function () {
          expect(component.get("isVisible")).toBeDefined();
        });

        it("it should set 'isVisible' to true by default", function () {
          expect(DeleteMultipleSubItems.get("isVisible")).toBe(true);
        });

        it("it should have a 'toggle' function that either shows or hides the DeleteMultipleSubItems component depending on the 'isVisible' property", function () {
          expect(component.toggle).toBeDefined();
        });
      });
    });
  };

  runTests(jasmineEnv, setupTests);
});