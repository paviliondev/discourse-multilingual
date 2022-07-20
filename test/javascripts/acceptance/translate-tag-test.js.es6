import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { tag_translations } from "../fixtures/tag-translations";
import I18n from "I18n";

acceptance("Translated tags", function () {
  I18n.tag_translations = tag_translations;

  test("translates included data correctly", async (assert) => {
    I18n.locale = "fr";
    assert.equal(I18n.default.currentLocale(), "fr");
    assert.equal(I18n.translate_tag("motor-car"), "voiture");
  });

  test("translates included data correctly", async (assert) => {
    I18n.locale = "en";
    assert.equal(I18n.default.currentLocale(), "en");
    assert.equal(I18n.translate_tag("motor-car"), "motor-car");
  });
});
