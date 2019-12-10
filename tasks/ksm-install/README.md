# ksm-install

**Describe your test Here**

Currently this test accepts a name in the environment variable `GREETING_NAME`,
and logs output in the form of:

    `hello <GREETING_NAME>`

For more information see the [ISV-CI Test Toolkit]()

# Running for the first time

If you execute:

`GREETING_NAME="me" make run`

You should see:

```
section-start greet
hello my friend
section-end greet
```