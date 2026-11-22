#include <errno.h>
#include <fcntl.h>
#include <libmtp.h>
#include <unistd.h>

static inline int droidbridge_open_source(const char *path) {
    return open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
}

static inline uint16_t droidbridge_read_upload(
    void *params, void *context, uint32_t requested, unsigned char *buffer, uint32_t *received
) {
    (void)params;
    *received = 0;
    if (requested == 0) {
        return LIBMTP_HANDLER_RETURN_OK;
    }

    int descriptor = *(const int *)context;
    ssize_t count;
    do {
        count = read(descriptor, buffer, requested);
    } while (count < 0 && errno == EINTR);

    // A nonempty request at EOF means that the source shrank after its size was read.
    if (count <= 0) {
        return LIBMTP_HANDLER_RETURN_ERROR;
    }
    *received = (uint32_t)count;
    return LIBMTP_HANDLER_RETURN_OK;
}
