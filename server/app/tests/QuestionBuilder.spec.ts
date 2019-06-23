import { QuestionBuilder } from "../models/Question";

test('question builder', () => {
  const qb = new QuestionBuilder();
  const x = qb.withTitle('coucou')
  .withBadAnswer('bad')
  .withBadAnswer('bad1')
  .withBadAnswer('bad2')
  .withGoodAnswer('good')
  .build();
  
  const testOk = {};
  
  for (const a of x.possibleResponses) {
    testOk[a.id] = 1;
  }
  const ok = testOk[0] != null && testOk[1] != null && testOk[2] != null && testOk[3] != null;
  expect(ok).toBe(true);
  expect(x.goodResponse.text).toBe('good');
});