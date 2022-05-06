import {
  acceptance,
  updateCurrentUser,
} from "discourse/tests/helpers/qunit-helpers";

const content_languages = [{ code: "aa", name: "Qafár af" }];

acceptance("Content languages dropdown", function (needs) {
  needs.user();
  needs.settings({
    multilingual_enabled: true,
    multilingual_content_languages_enabled: true,
  });
  needs.site({ content_languages });

  test("displays user's content languages", async (assert) => {
    updateCurrentUser({ content_languages });

    await visit("/");

    assert.equal(
      find(".content-languages-dropdown summary").hasClass("has-languages"),
      true,
      "has content languages"
    );

    await click(".content-languages-dropdown summary");

    assert.equal(
      find(".content-languages-dropdown .select-kit-collection li").length,
      2,
      "it should render content languages add the set languages link"
    );
  });
});
