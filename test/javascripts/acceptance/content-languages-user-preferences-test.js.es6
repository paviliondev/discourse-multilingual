import {
  acceptance,
  exists,
  loggedInUser,
} from "discourse/tests/helpers/qunit-helpers";
import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";

const content_languages = [
  { locale: "aa", name: "Qafár af" },
  { locale: "ab", name: "аҧсуа бызшәа" },
];

acceptance(
  "User interface preferences when topic filtering disabled",
  function (needs) {
    needs.user();
    needs.settings({
      multilingual_enabled: true,
      multilingual_content_languages_enabled: true,
      multilingual_content_languages_topic_filtering_enabled: false,
    });

    test("content languages selector", async (assert) => {
      await visit(`/u/${loggedInUser().username}/preferences/interface`);

      assert.ok(!exists(".content-languages-selector"), "does not display");
    });
  }
);

acceptance(
  "User interface preferences when topic filtering enabled",
  function (needs) {
    needs.user();
    needs.settings({
      multilingual_enabled: true,
      multilingual_content_languages_enabled: true,
      multilingual_content_languages_topic_filtering_enabled: true,
    });
    needs.site({ content_languages });

    test("content languages selector", async (assert) => {
      await visit(`/u/${loggedInUser().username}/preferences/interface`);

      assert.ok(exists(".content-languages-selector summary"), "displays");

      await click(".content-languages-selector summary");

      assert.equal(
        find(".content-languages-selector .select-kit-collection li").length,
        2,
        "displays the content languages"
      );
    });
  }
);
