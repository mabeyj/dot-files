# Personal preferences for code

Ensure code is readable and maintainable.

Project conventions take priority over my preferences.

## Language

For documentation and comments, I prefer Canadian English.

For class, function, and variable names, I prefer matching the conventions of
the current language, which is usually American English.

## Line length

I prefer a maximum line length of 80 characters. Code formatting tools will
usually enforce this, except that comments usually need to be wrapped
manually.

This limit can be exceeded when it is more readable, such as for long strings
or URLs.

## Accessibility

Follow the latest versions of WCAG and WAI-ARIA when implementing UI
components.

## Documentation

For serious projects, I prefer documenting public classes and functions.

Docstrings are intended for the reader who wants to use a class, class
property, or function, describing what it is or does. Implementation details
belong in ordinary comments inside the body instead.

For test suites, docstrings are not necessary and overall documentation can be
lax. Common test utilities should be properly documented like normal code.

## Comments

Prefer comments that document rationale, gotchas, to-dos, and things that are
not obvious from reading the code itself. Avoid comments that add unnecessary
clutter such as:

- Restating what the code already says.
- Restating what the Git history already shows.
- Describing changes that ultimately would not matter to future readers.
- Legacy behaviours that have been removed and are no longer applicable.

Comments should be concise and used sparingly. On average, 1 to 3 lines. Longer
ones should be rare.

If an investigation warrants leaving a comment, just stick to the conclusion.
The whole process is likely not relevant for future readers. Instead, consider
placing full technical details in a plan file for future reference.

Comments should not use Markdown formatting, except that inline code
formatting (`backticks`) is acceptable in the following cases, where it
improves readability and avoids confusion:

- When it is ambiguous whether a word is a normal word or a reference to a
  class/function/variable name, keyword, or filename.

  ```
  GOOD: // This `if` is necessary.
  BAD:  // This if is necessary.
  ```

- When code examples or commands appear in the middle of prose.

  ```
  GOOD: // Run `cache clear` afterwards.
  GOOD: // Run this afterwards: cache clear
  BAD:  // Run cache clear afterwards.
  ```

For software and package names, preferably use their canonical names if they
have any, like React Intl instead of react-intl. Either be consistent with
nearby comments or refer to the project's website or documentation to find the
canonical name used in prose.

For URLs, preferably place them after a colon or on their own line for clear
separation from prose and any surrounding punctuation.

```
GOOD: // See: https://example.com
BAD:  // See https://example.com.
```

Comments may be tagged with a topic for increased visibility, such as:

- TODO
- DEPRECATED
- LEGACY
- PERFORMANCE
- SECURITY

```
// TODO: Remove after upgrading to the latest version.
// PERFORMANCE: This is specifically set up to use an index scan.
```

## Tests

For serious projects, I prefer writing unit and integration tests, making sure
the project is well tested.
