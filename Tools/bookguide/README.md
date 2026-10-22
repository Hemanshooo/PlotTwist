# Book guides

Plot Twist writes every twist on the phone with Apple Intelligence. That model can hold only about 3,000 words at a time, so it can't read a novel. Instead, ChatGPT reads each book **once**, from its full text on [Project Gutenberg](https://www.gutenberg.org), and leaves a guide the app is built with.

A guide (`Otherwise/Resources/Guides/<slug>.guide.json`) holds:

- a spoiler-free **premise**;
- the main **characters**: names, other names, who they are;
- a summary of **every chapter**;
- the **turning points**, each with the **original passage**, the people in it, and what it led to.

ChatGPT points to where each turning point begins by quoting a line. The script then finds that line in the real text and cuts the passage from the book itself, so passages are always word-for-word and each moment's place in the book is measured, not guessed. For the twelve classics the app already maps, ChatGPT checks the hand-written moments against the text instead of choosing new ones.

When you twist a moment, the phone's model is given the original scene, the characters in it and what followed, all within its memory budget. A change off the map gets the characters it names and the chapters it's about.

## Running it

You need Python 3 (it comes with Xcode's command-line tools) and an OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys).

1. Save the key in `Tools/bookguide/.env` (git ignores this file):

   ```
   OPENAI_API_KEY=sk-...
   ```

2. From the project folder, in Terminal:

   ```sh
   python3 Tools/bookguide/build.py --all --dry-run       # download the books, see the cost
   python3 Tools/bookguide/build.py pride-and-prejudice   # build one guide
   python3 Tools/bookguide/build.py --all                 # build every guide in books.json
   ```

3. Build the app in Xcode. Guides are picked up automatically.

Any other Gutenberg book can be added by its number (it's in the book's URL on gutenberg.org). It appears in the library with its guide:

```sh
python3 Tools/bookguide/build.py --gutenberg 158 --slug emma --year 1815
```

Options:

- `--model gpt-6-astra`: use another model. The default is `gpt-6.1-sol`. `gpt-6-luna` is cheapest.
- `--force`: rebuild a guide that already exists.
- `--from-response cache/<slug>.response.json`: rebuild from a saved answer without asking ChatGPT again.

Set `PLOTTWIST_CONTACT=you@example.com` to tell Gutenberg and Open Library who is downloading.

## What it costs

A typical novel is 150,000–250,000 tokens, read once. At `gpt-6.1-sol` prices ($2 per million tokens in, $10 out) that's about $0.40–$0.70 per book. *The Count of Monte Cristo* (about 600,000 tokens) is about $1.40. `--dry-run` prints an estimate for each book first.

## Notes

- Downloads are cached in `Tools/bookguide/cache/` and are only fetched once, with a pause between files, as Gutenberg asks. For hundreds of books, follow Gutenberg's [guidance for automated access](https://www.gutenberg.org/policy/robot_access.html) and use a mirror.
- The texts are public domain in the US. Check the copyright status of 20th-century books in each country you publish in.
- The app doesn't use the Project Gutenberg name. Its licence asks that anything other than a verbatim copy carries no Gutenberg references.
- Check warnings in the output. A quote ChatGPT couldn't copy exactly leaves that moment without a passage; rebuilding with `--force` usually fixes it.
