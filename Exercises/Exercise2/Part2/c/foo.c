#include <pthread.h>
#include <stdio.h>

int i = 0;
pthread_mutex_t i_mutex;

// Note the return type: void*
void* incrementingThreadFunction(){
    // TODO: sync access to i
    for (int k = 0; k < 1000000; k++){
        while (pthread_mutex_lock(&i_mutex)) {
            i++;
            pthread_mutex_unlock(&i_mutex)
        }
    }
    return NULL;
}

void* decrementingThreadFunction(){
    // TODO: sync access to i
    for (int j = 0; j < 1000000; j++){
        while (pthread_mutex_lock(&i_mutex)) {
            i--;
            pthread_mutex_unlock(&i_mutex)
        }
    }
    return NULL;
}


int main(){

    pthread_t incrementingThread;
    pthread_t decrementingThread;

    pthread_create(&incrementingThread, NULL, incrementingThreadFunction, NULL);
    pthread_create(&decrementingThread, NULL, decrementingThreadFunction, NULL);

    pthread_join(incrementingThread, NULL);
    pthread_join(decrementingThread, NULL);


    printf("The magic number is: %d\n", i);
    return 0;
}
