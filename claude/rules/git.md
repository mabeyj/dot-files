# Personal preferences for Git

I prefer small, focused commits.

If there are any changes to related tests or translation strings, I prefer
including them all in the same commit as the actual code changes rather than
separately.

I will run `git commit` myself after manual code review and testing.

When stopping to commit, summarize the changes and suggest a commit message.
If I have not already started staging something unrelated, you can stage the
recommended changes for the next commit.

## Commit messages

I prefer commit messages that are just the header (first line). I only write a
body sparingly, such as:

- When there are too many changes to fit in one line, so they are listed in
  the body instead.

- When there is rationale not already documented in the code.

Target 50 characters for the header. 72 is the hard limit. Write the header
naturally first, then count. Only shorten it if it is actually over 50. Never
preemptively abbreviate a message that already fits.

Techniques for shortening:

- Drop filler words like "a" or "the" before abbreviating.
- Similar names can be collapsed with glob braces like `get{One,Two}`.
- Use "&" or "w/" only if the above are not enough.
- Never trim meaning to fit (don't shorten `val=true` to just `val`).

If the header is too short to articulate the changes well, use something
generic and then go into detail in the body of the commit message.

### Examples

- Add someFunction utility
- Add SomeClass.someFunction
- Implement some feature
- Remove unused someFunction method
- Fix something not working
