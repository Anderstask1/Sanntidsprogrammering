# Mutex and Channel basics

### What is an atomic operation?
> *An atomic operation in concurrent programming is operations running completely independent of all other operations. Of that reason the operation is guaranteed to avoid interruptions, multi-threading and multi-processing. In other words, the operations is not splittable in parts. Hence any other thread will eighter see the value of an atomic operation before or after the operation, not the intermediate value.*

### What is a semaphore?
> *A semaphore is a variable used to control access to common resources by multiple processes in a concurrent system. It is typically a record of how many units of resource are available, together with operations to manipulate that record in a safe manner, to avoid race conditions.*

### What is a mutex?
> *When I am having a big heated discussion at work, I use a rubber chicken which I keep in my desk for just such occasions. The person holding the chicken is the only person who is allowed to talk. If you don't hold the chicken you cannot speak. You can only indicate that you want the chicken and wait until you get it before you speak. Once you have finished speaking, you can hand the chicken back to the moderator who will hand it to the next person to speak. This ensures that people do not speak over each other, and also have their own space to talk.*
>*- stack overflow*

>*= mutual exclusion semaphores.*

### What is the difference between a mutex and a binary semaphore?
> *A mutex is protecting a resource from access. The task/thread that takes the mutex owns it, and no other task/thread can take the mutex before it is released. A binary semaphore is a mechanism for sharing resources between different processes/threads, by letting a process notify another process when the resource is available.*

### What is a critical section?
> *A critical section is a sections of code that only one thread can execute at a time. This is due to the fact that the code accesses shared resources. In other words, a critical section has to executed as an atomic operation.*

### What is the difference between race conditions and data races?

 >*- A data race occurs when 2 instructions from different threads access the same memory location, at least one of these accesses is a write and there is no synchronization that is mandating any particular order among these accesses.*

>*- A race condition is a semantic error. It is a flaw that occurs in the timing or the ordering of events that leads to erroneous program behavior (feilaktig programoppførsel). Many race conditions can be caused by data races, but this is not necessary.*

### List some advantages of using message passing over lock-based synchronization primitives.
>*- The state of Mutable/Shared objects are harder to reason about in a context where multiple threads run
concurrently.*

>*- Synchronizing on a Shared Objects would lead to algorithms that are inherently non-wait free or non-lock free.*

>*- In a multiprocessor system, a shared object can be duplicated across processor caches. Even with the use of Compare and swap based algorithms that doesn't require synchronization, it is possible that a lot of processor cycles will be spent sending cache coherence messages to each of the processors.*

>*- A system built of message passing semantics is inherently more scalable. Since message passing implies that messages are sent asynchronously, the sender is not required to block until the receiver acts on the message.*

### List some advantages of using lock-based synchronization primitives over message passing.
>*- Some algorithms tend to be much simpler.*

>*- A message passing system that requires resources to be locked will eventually degenerate into a shared object systems. This is sometimes apparent in Erlang when programmers start using ets tables etc. to store shared state.*

>*- If algorithms are wait-free, you will see improved performance and reduced memory footprint as there is much less object allocation in the form of new messages.*
