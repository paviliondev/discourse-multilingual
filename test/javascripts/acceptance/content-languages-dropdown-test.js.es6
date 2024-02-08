import {
  acceptance,
  exists,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, visit } from "@ember/test-helpers";

const content_languages = [{ locale: "aa", name: "Qafár af" }];

acceptance(
  "Discovery navigation when topic filtering disabled",
  function (needs) {
    needs.user();
    needs.settings({
      multilingual_enabled: true,
      multilingual_content_languages_enabled: true,
      multilingual_content_languages_topic_filtering_enabled: false,
    });

    test("content languages dropdown", async (assert) => {
      await visit("/");

      assert.ok(!exists(".content-languages-dropdown"), "does not display");
    });
  }
);

acceptance(
  "Discovery navigation when topic filtering enabled",
  function (needs) {
    needs.user();
    needs.settings({
      multilingual_enabled: true,
      multilingual_content_languages_enabled: true,
      multilingual_content_languages_topic_filtering_enabled: true,
    });
    needs.site({ content_languages });

    test("content languages dropdown", async (assert) => {
      updateCurrentUser({ content_languages });

      await visit("/");

      assert.ok(exists(".content-languages-dropdown"), "displays");

      assert.dom(".content-languages-dropdown summary.has-languages").exists();

      await click(".content-languages-dropdown summary");

      assert
        .dom(".content-languages-dropdown .select-kit-collection li")
        .exists(
          {
            count: 2,
          },
          "displays content languages and Set languages link"
        );
    });
  }
);
