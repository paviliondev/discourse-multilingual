import { acceptance, updateCurrentUser } from "helpers/qunit-helpers";
import { topicList } from '../fixtures/topic-list';

acceptance("Content languages tags", {
  loggedIn: true,
  settings: {
    multilingual_enabled: true,
    tagging_enabled: true
  },
  site: {
    content_languages: [ { code: 'aa', name: 'Qafár af' } ]
  }
});

test("displays language tags correctly", async assert => {
  server.get('/latest.json', () => topicList);    
  await visit("/");
  assert.equal(find(`.topic-languages .discourse-tag:eq(0)`).text(), "Qafár af");
});