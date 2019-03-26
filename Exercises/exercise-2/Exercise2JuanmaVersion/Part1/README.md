# Mutex and Channel basics

### What is an atomic operation?
> *Atomic operation is a type of operation during which a processor can simultaneously read a location and write it in the same bus operation. This can solve the problems of the Exercise1's program where the operations inside the loops could be interrumped (since adding +1 to a variable consisted of 3 operations). Atomic implies indivisibility and irreducibility, so an atomic operation must be performed entirely or not performed at all.*

### What is a semaphore?
> *Semaphore is a variable or abstract data type used to control access to a common resource by multiple processes in a concurrent system. This mecanins avoid the critical sections problems of two different processes colliding. The processes should change the semaphore value to change the "color" of the semaphore and unlock the usage.*

### What is a mutex?
> *Is a type of semaphore that provides mutual exclusion. Is a key to a toilet. One person can have the key - occupy the toilet - at the time. When finished, the person gives (frees) the key to the next person in the queue.. It acts as a gate keeper to a section of code allowing one thread in and blocking access to all others.*

### What is the difference between a mutex and a binary semaphore?
> *Both are types of semaphores but mutex can be released only by thread that had acquired it, while you can signal semaphore from any other thread (or process).*

### What is a critical section?
> *Is a section of the program where the shared resource is accesed. This can lead to unexpected or erroneous behavior, for this reason critical sections should be protected.*

### What is the difference between race conditions and data races?
 > *The race condition is a situation where the result of using a resource simultaneously depends on ordering in time.It is a semantic error. It is a flaw that occurs in the timing or the ordering of events that leads to erroneous program behavior. Many race conditions can be caused by data races, but this is not necessary.*
 
 > *A data race occurs when 2 instructions from different threads access the same memory location, at least one of these accesses is a write and there is no synchronization that is mandating any particular order among these accesses.*

### List some advantages of using message passing over lock-based synchronization primitives.
> *-It is easier to build massively parallel hardware. Message passing programming models tend to be more tolerant of higher communication latencies.*

> *-The communication is explicit, simpler to understand.*

### List some advantages of using lock-based synchronization primitives over message passing.
> *-Some algorithms tend to be much simpler.*

> *-A message passing system that requires resources to be locked will eventually degenerate into a shared object systems.*

> *-If algorithms are wait-free, you will see improved performance and reduced memory footprint as there is much less object allocation in the form of new messages.*
