---
layout: post
post_title: '[EN] To mock, or not to mock, that is the question'
title: '[EN] To mock, or not to mock, that is the question'
description: 'Checklist, aimed to help you protect yourself from wrong usage of mocks and stubs'
lang: 'enUS'
---
* Time: 5-10 min
* Level: Beginner/Intermediate

The following checklist is aimed to help you protect yourself from improper usage of mocks and stubs.
You may find yourself willing to add/remove items from the list – that is totally OK, just make sure that you stick
to your final version.

Mocking has been a controversial practice from the very moment I've heard about it for the first time, however most
people agree that mocking is a tool and as any other tool it can’t be good or bad, rather it’s developers obligation
to pick the right tool for the job and make most of the features it provides.

You’re doing it wrong if:

1. Mocking things you don’t own – External Service, IO, System, etc.
  * if appropriate, add an Adapter as a wrapper around a thing and mock it instead
2. Mocking thing under test
  * you may want to introduce and mock collaborator instead
3. Mocking trivial things
  * you may use an actual thing instead of a mock
4. Mocking when you should be stubbing
  * test for observable behavior instead of methods being called, methods are only an implementation detail
5. Mocking only a part of a collaborator’s interface
  * mock it entirely or do not mock at all
6. Mocking at wrong level/layer
  * for unit tests – mock your nearest neighbor
  * for regression safety – mock dependency at the lowest possible level

  If you have not violated any of the upper items, and your tests still are brittle or make you cry at night – that
  may be an indication of a bad design. If that's the case – it doesn't matter either you mock or not because the
  problem exists between the chair and computer.

# References

* [Justin Searls – Please don’t mock me][ref_1]{:target='_blank_'}
* [Avdi Grimm - Episode #287: Mocking Smells 1][ref_2]{:target='_blank_'}
* [Avdi Grimm - Episode #289: Mocking Smells 2][ref_3]{:target='_blank_'}
* [Avdi Grimm - Episode #296: Mocking Smells 3][ref_4]{:target='_blank_'}
* [Avdi Grimm - Episode #312: Mocking Smells 4][ref_5]{:target='_blank_'}
* [Avdi Grimm - Episode #052: The End of Mocking][ref_6]{:target='_blank_'}
* [Robert C. Martin - The Little Mocker][ref_7]{:target='_blank_'}
* [Robert C. Martin - When To Mock][ref_8]{:target='_blank_'}
* [Kent Beck - Programmer Test Principles][ref_9]{:target='_blank_'}
* [Martin Fowler - UnitTest][ref_10]{:target='_blank_'}
* [Martin Fowler - The Practical Test Pyramid][ref_11]{:target='_blank_'}
* [Bill Wake - 3A – Arrange, Act, Assert][ref_12]{:target='_blank_'}
* [James Shore - Testing Without Mocks: A Pattern Language][ref_13]{:target='_blank_'}

[ref_1]: https://www.youtube.com/watch?v=Af4M8GMoxi4
[ref_2]: https://www.rubytapas.com/2015/03/05/episode-287-mocking-smells/
[ref_3]: https://www.rubytapas.com/2015/03/12/episode-289-mocking-smells-2/
[ref_4]: https://www.rubytapas.com/2015/04/06/episode-296-mocking-smells-3/
[ref_5]: https://www.rubytapas.com/2015/06/01/episode-312-mocking-smells-4/
[ref_6]: https://www.rubytapas.com/2013/01/28/episode-052-the-end-of-mocking/
[ref_7]: https://blog.cleancoder.com/uncle-bob/2014/05/14/TheLittleMocker.html
[ref_8]: https://blog.cleancoder.com/uncle-bob/2014/05/10/WhenToMock.html
[ref_9]: https://medium.com/@kentbeck_7670/programmer-test-principles-d01c064d7934
[ref_10]: https://martinfowler.com/bliki/UnitTest.html
[ref_11]: https://martinfowler.com/articles/practical-test-pyramid.html#MockingAndStubbing
[ref_12]: https://xp123.com/articles/3a-arrange-act-assert/
[ref_13]: https://www.jamesshore.com/Blog/Testing-Without-Mocks.html
