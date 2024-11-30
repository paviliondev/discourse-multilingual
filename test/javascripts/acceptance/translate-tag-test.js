import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import I18n from "I18n";
import { multilingualTagTranslator } from "discourse/plugins/discourse-multilingual/discourse/lib/multilingual-tag";
import { tag_translations } from "../fixtures/tag-translations";

acceptance("Translated tags", function () {
  I18n.tag_translations = tag_translations;

  test("translates included data correctly", async (assert) => {
    I18n.locale = "fr";
    assert.equal(I18n.currentLocale(), "fr");
    assert.equal(multilingualTagTranslator("motor-car"), "voiture");
  });

  test("doesn't translate tag when data does not include translation", async (assert) => {
    I18n.locale = "en";
    assert.equal(I18n.currentLocale(), "en");
    assert.equal(multilingualTagTranslator("motor-car"), "motor-car");
  });
});
