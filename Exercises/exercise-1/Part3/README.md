# Reasons for concurrency and parallelism


To complete this exercise you will have to use git. Create one or several commits that adds answers to the following questions and push it to your groups repository to complete the task.

When answering the questions, remember to use all the resources at your disposal. Asking the internet isn't a form of "cheating", it's a way of learning.

 ### What is concurrency? What is parallelism? What's the difference?
 > *Concurrency is a type of computing where progress happens on more than one task at a time, typically during overlapping periods, instead of one at a time (as in sequential computing). In parallelism, tasks is divided into subtask which can be processed at the exactly same time, in parallel. The two terms is similar, but not the same. Concurrency can be implemented on a single CPU, where the application don't process several task at the same time, but it do not completely finish a task before beginning on the next. Parallelism computes subproblems at the same time on multiple CPUs. In other words, concurrency is related to how an application handles multiple tasks, but parallelism is related to how an application handles each individual task.*

 ### Why have machines become increasingly multicore in the past decade?
 > *Due to the fact that the power consumption of CPUs when engineers pushed the frequency scaling became economical inefficient, the trend to use of multicore machines and parallelization quickly escalated. The power consumption increased fast with the increase of frequency because factors like heat losses and leakage current.*

 ### What kinds of problems motivates the need for concurrent execution?
 (Or phrased differently: What problems do concurrency help in solving?)
 > **

 ### Does creating concurrent programs make the programmer's life easier? Harder? Maybe both?
 (Come back to this after you have worked on part 4 of this exercise)
 > *To be able to compute a problem using concurrency it is necessary to establish communication between the threads being executed, and to avoid wrong outputs and crashing. Of that reason, while it may reduce the computational time immensely, the creation of concurrent programs will most likely make the programmer's life harder. But this statement obviously depends on the kind of program being solved.*

 ### What are the differences between processes, threads, green threads, and coroutines?
 > *- A process is in computing an instance of a program being executed, and is managed by the operating system. The process contains the program code and the current activity. This process may, depending on the specific OS, consist of multiple threads resulting in a true concurrent behavior.

 - A thread is a sequence of instructions within a process. The threads is executed inside a process, which again is executed within the OS kernel (kernel = core of a computer's operating system, with complete control over everything in the system). A thread is simply a path of execution within a process.

 - A green thread is a thread, but is scheduled by a virtual machine instead of the OS. This leads to emulating multithreaded environments in user space, and not in kernel space.

 - A coroutine is a technique for decomposing complex computations. Similar to a subroutine, a coroutine computes a single step of a complex problem, but without a main function to coordinate the results. The coroutines link together themselves, forming a pipeline. Coroutines is a form of concurrency that is useful, and is able to avoid difficulties like race-conditions, deadlocks etc. completely.*

 ### Which one of these do `pthread_create()` (C/POSIX), `threading.Thread()` (Python), `go` (Go) create?
 > *- `pthread_create()` creates a new thread in the calling process.
 > *- `pthread_create()` creates a new thread in the calling process. = threads

 - `threading.Thread()` is a class representing a thread of control (constructor should always be called with keyword arguments).
 - `threading.Thread()` is a class representing a thread of control (constructor should always be called with keyword arguments). = green threads

 - `go` in Golang it is not possible to control the threads.*
 - `go` in Golang it is not possible to control the threads. = coroutines*

 ### How does pythons Global Interpreter Lock (GIL) influence the way a python Thread behaves?
 > *Since Python's memory management is not thread-safe, GIL prevents multiple threads from executing Python bytecodes at once. GIL is a mutex (aka a lock) which allows only one thread to execute at a time even in a multi-threaded architecture with more than one CPU core. GIL prevents leaked memory that is never released or, even worse, incorrectly release the memory while a reference to that object still exists.*

 ### With this in mind: What is the workaround for the GIL (Hint: it's another module)?
 > *If one use multi-processing, instead of multi-threading, the problem is resolved. Each Python process gets its own Python interpreter and memory space so the GIL won’t be a problem. Python has a multiprocessing module which makes it easy to create processes.*

 ### What does `func GOMAXPROCS(n int) int` change?
 > *func GOMAXPROCS(n int) int change the maximum number of CPUs that can be executing simultaneously, and returns the previous setting as well.*
