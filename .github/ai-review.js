import * as core from '@actions/core';
import { execSync } from 'child_process';
import OpenAI from 'openai';
import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';

(async () => {
  try {
    /* ---------------- collect the diff ---------------- */
    const before = process.env.GITHUB_EVENT_BEFORE;
    const after  = process.env.GITHUB_EVENT_AFTER;
    const fullDiff = execSync(`git diff ${before} ${after}`, { encoding: 'utf8' });

    const MAX_CHARS = 30_000;                               // ~10 k tokens
    const diff = fullDiff.length > MAX_CHARS
      ? `${fullDiff.slice(0, MAX_CHARS)}\n\n--- DIFF TRUNCATED ---`
      : fullDiff;

    console.log('----DIFF START----');
    console.log(diff);
    console.log('----DIFF END----');

    /* ---------------- define the allowed reply shape --- */
    const Verdict = z.object({
      verdict:  z.enum(['PASS', 'FAIL']),
      feedback: z.string().optional()   // explanation when verdict === "FAIL"
    }).strict();

    const jsonSchema = {
      name:        'ai_review_verdict',
      description: 'Return PASS if the diff looks safe; otherwise FAIL and explain why in "feedback".',
      schema:      zodToJsonSchema(Verdict)
    };

    /* ---------------- call OpenAI ---------------------- */
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

    const resp = await openai.chat.completions.create({
      model: 'gpt-4o-mini',               // latest lightweight model (Jun 2025)
      temperature: 0,
      messages: [
        {
          role: 'system',
          content:
            'You are a meticulous senior engineer. ' +
            'Return ONLY a JSON object that satisfies the provided schema.'
        },
        {
          role: 'user',
          content: `Project context:
This project is a basic flask server that serves documentation for my other 2 projects and provides a simple webpage to access them individually. 

The 2 sub projects are imported as git submodules - they are called LADA and SUPER-GIANT. LADA is a local ai coding assisntat and SUPER-GIANT is a framework for training LLMs for scratch.

Again this project is just a visualisation and glue between them.

Diff under review:
\`\`\`diff
${diff}
\`\`\`

If the code of this diff seems wrong (incorrect logic, broken syntax, security issue, missing tests, etc.) respond with:
\`\`\`json
{ "verdict": "FAIL", "feedback": "<concise explanation (≈100 words max)>" }
\`\`\`
Otherwise respond with:
\`\`\`json
{ "verdict": "PASS" }
\`\`\``
        }
      ],
      response_format: { type: 'json_schema', json_schema: jsonSchema }
    });

    /* ---------------- inspect + act on reply ----------- */
    console.log('----RESPONSE START----');
    console.log(resp.choices[0].message.content);
    console.log('----RESPONSE END----');

    const { verdict, feedback } = Verdict.parse(
      JSON.parse(resp.choices[0].message.content)
    );

    core.notice(`Model verdict: ${verdict}`);
    if (feedback) {
      core.error(`AI feedback: ${feedback}`);          // red annotation in log

      // Also surface it nicely in the Summary tab
      await core.summary
        .addHeading('AI Review Feedback')
        .addParagraph(feedback)
        .write();
    }

    if (verdict !== 'PASS') {
      core.setFailed('AI review failed.');
      process.exit(1);
    }
  } catch (err) {
    core.setFailed(err instanceof Error ? err.message : String(err));
  }
})();
