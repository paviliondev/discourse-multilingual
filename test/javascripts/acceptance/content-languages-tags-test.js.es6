import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { topicList } from "../fixtures/topic-list";
import { visit } from "@ember/test-helpers";

const content_languages = [{ code: "aa", name: "Qafár af" }];

acceptance("Content language tags", function (needs) {
  needs.user();
  needs.settings({
    multilingual_enabled: true,
    multilingual_content_languages_enabled: true,
    tagging_enabled: true,
  });
  needs.site({ content_languages });

  needs.pretender((server) => {
    server.get("/latest.json", () => topicList);
  });

  test("displays content language tags correctly", async (assert) => {
    await visit("/");
    assert.equal(
      find(`.content-language-tags .discourse-tag:eq(0)`).text(),
      "Qafár af"
    );
  });
});
