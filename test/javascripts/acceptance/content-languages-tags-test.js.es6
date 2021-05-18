import { acceptance, updateCurrentUser } from "discourse/tests/helpers/qunit-helpers";
import { topicList } from '../fixtures/topic-list';

const content_languages = [{ code: 'aa', name: 'Qafár af' }];

acceptance("Content language tags", function (needs) {
  needs.user();
  needs.settings({
    multilingual_enabled: true,
    multilingual_content_languages_enabled: true,
    tagging_enabled: true
  });
  needs.site({ content_languages });

  test("displays content language tags correctly", async assert => {
    server.get('/latest.json', () => topicList);
    await visit("/");
    assert.equal(find(`.content-language-tags .discourse-tag:eq(0)`).text(), "Qafár af");
  });
});
