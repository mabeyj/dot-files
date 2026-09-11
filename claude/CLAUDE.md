# Personal preferences

## Response preferences

For agent responses, use Canadian English. Avoid excessive use of em dashes
(`—`).

When giving me multiple steps of instructions to follow, format them as a
numbered list.

## Workflow

1. **Plan first:** Break up large scopes into smaller tasks. Pause for any
   feedback or open questions before proceeding with implementation.

2. **Implementation:** Implement one task at a time or a small set of related
   tasks. Run tests and code quality tools. Then, pass back for review.

3. **Review:** I will manually review, test, and scrutinize your work. There
   might be additional feedback or questions to address, which may require
   another round of changes and review. If everything is good, I will commit
   it, and then we will move on to the next task.

## Deciding the scope of tasks

I use the following general guidelines for deciding how to break up a larger
scope into multiple tasks or individual commits:

- Focus on adding or modifying utility functions first, then the data layer,
  then the API or view layer, then the front-end or UI layer.

- Focus on a single large or complex function separately from other changes.

- Focus on a set of small, related changes across multiple files, like renaming
  something across multiple files.

## Review

Things to expect from code review:

- Formatting changes from code quality tools
- Manual cleanup, rearranging, or refactoring
- Changes to help improve human readability of the code
- Changes to wording to make it sound less AI-generated
- Changes to follow project conventions
- Changes to improve consistency with other code
- Nitpicks

# Local environment

I am running Arch Linux, so the software I have installed is usually the latest
available. Occasionally, this runs into compatibility issues that might need to
be worked around.

For safety reasons (data exfiltration, accidental deletion, etc.), I run Claude
Code in a Bubblewrap sandbox, optionally with Sandlock for additional network
restrictions. Access is restricted to certain project directories,
non-sensitive files, and common system directories. You can find the sandbox
scripts in `~/.local/bin`.

If something isn't working right, it might be because of the sandbox. Just let
me know and I can look into granting access. Reconfiguring and restarting the
sandbox is cheap and is unlikely to interfere with the current session.

If you run into a command that's missing on this system and it would help you
work more efficiently, feel free to suggest the package to install.
