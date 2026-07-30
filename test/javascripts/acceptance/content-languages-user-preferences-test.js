import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  loggedInUser,
} from "discourse/tests/helpers/qunit-helpers";

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

      assert
        .dom(".content-languages-selector")
        .doesNotExist("does not display");
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

      assert.dom(".content-languages-selector summary").exists("displays");

      await click(".content-languages-selector summary");

      assert
        .dom(".content-languages-selector .select-kit-collection li")
        .exists(
          {
            count: 2,
          },
          "displays content languages"
        );
    });
  }
);
