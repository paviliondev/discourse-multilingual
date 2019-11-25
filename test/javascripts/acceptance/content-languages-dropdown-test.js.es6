import { acceptance, updateCurrentUser } from "helpers/qunit-helpers";

acceptance("Content languages dropdown", {
  loggedIn: true,
  settings: {
    multilingual_enabled: true
  }
});

test("displays user's content languages", async assert => {  
  updateCurrentUser({ content_languages: [ { code: 'aa', name: 'Qafár af' } ] })
    
  await visit("/");
  
  assert.equal(
    find('.content-languages-dropdown').hasClass("has-selection"),
    true,
    "has content languages"
  );
  
  await click(".content-languages-dropdown button");
    
  assert.equal(
    find('.content-languages-dropdown .select-kit-collection li').length,
    2,
    'it should render content languages add the set languages link'
  );
});