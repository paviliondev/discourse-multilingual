import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { tag_translations } from "../fixtures/tag-translations";
import { multilingualTagTranslator } from "discourse/plugins/discourse-multilingual/discourse/lib/multilingual-tag";
import I18n from "I18n";

acceptance("Translated tags", function () {
  I18n.tag_translations = tag_translations;

  test("translates included data correctly", async (assert) => {
    I18n.locale = "fr";
    assert.equal(I18n.default.currentLocale(), "fr");
    assert.equal(multilingualTagTranslator("motor-car"), "voiture");
  });

  test("doesn't translate tag when data does not include translation", async (assert) => {
    I18n.locale = "en";
    assert.equal(I18n.default.currentLocale(), "en");
    assert.equal(multilingualTagTranslator("motor-car"), "motor-car");
  });
});
