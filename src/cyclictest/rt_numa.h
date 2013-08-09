/*
 * A numa library for cyclictest.
 * The functions here are designed to work whether cyclictest has been
 * compiled with numa support or not, and whether the user uses the --numa
 * option or not.
 * They should also work correctly with older versions of the numactl lib
 * such as the one found on RHEL5, or with the newer version 2 and above.
 *
 * (C) 2010 John Kacur <jkacur@redhat.com>
 * (C) 2010 Clark Williams <williams@redhat.com>
 *
 */

#ifndef _RT_NUMA_H
#define _RT_NUMA_H

#include "rt-utils.h"
#include "error.h"

static int numa = 0;

#ifdef NUMA
#include <numa.h>

#ifndef LIBNUMA_API_VERSION
#define LIBNUMA_API_VERSION 1
#endif

#if LIBNUMA_API_VERSION >= 2
typedef struct bitmask rt_bitmask_t;
#else
typedef struct {
	long *mask;
	int size;
} rt_bitmask_t;
#endif


static void *
threadalloc(size_t size, int node)
{
	if (node == -1)
		return malloc(size);
	return numa_alloc_onnode(size, node);
}

static void
threadfree(void *ptr, size_t size, int node)
{
	if (node == -1)
		free(ptr);
	else
		numa_free(ptr, size);
}

static void rt_numa_set_numa_run_on_node(int node, int cpu)
{
	int res;
	res = numa_run_on_node(node);
	if (res)
		warn("Could not set NUMA node %d for thread %d: %s\n",
				node, cpu, strerror(errno));
	return;
}

static void numa_on_and_available()
{
	if (numa && numa_available() == -1)
		fatal("--numa specified and numa functions not available.\n");
}

#if LIBNUMA_API_VERSION >= 2
static int rt_numa_numa_node_of_cpu(int cpu)
{
	int node;
	node = numa_node_of_cpu(cpu);
	if (node == -1)
		fatal("invalid cpu passed to numa_node_of_cpu(%d)\n", cpu);
	return node;
}

#else	/* LIBNUMA_API_VERSION == 1 */

static int rt_numa_numa_node_of_cpu(int cpu)
{
	unsigned char cpumask[256];
	int node, idx, bit;
	int max_node, max_cpus;

	max_node = numa_max_node();
	max_cpus = sysconf(_SC_NPROCESSORS_CONF);

	if (cpu > max_cpus) {
		errno = EINVAL;
		return -1;
	}

	/* calculate bitmask index and relative bit position of cpu */
	idx = cpu / 8;
	bit = cpu % 8;

	for (node = 0; node <= max_node; node++) {
		if (numa_node_to_cpus(node, (void *) cpumask, sizeof(cpumask)))
			return -1;

		if (cpumask[idx] & (1<<bit))
			return node;
	}
	errno = EINVAL;
	return -1;
}

#endif	/* LIBNUMA_API_VERSION */

static void *rt_numa_numa_alloc_onnode(size_t size, int node, int cpu)
{
	void *stack;
	stack = numa_alloc_onnode(size, node);
	if (stack == NULL)
		fatal("failed to allocate %d bytes on node %d for cpu %d\n",
				size, node, cpu);
	return stack;
}

/** Returns number of bits set in mask. */
static inline unsigned int rt_numa_bitmask_count(const rt_bitmask_t *mask)
{
	unsigned int num_bits = 0, i;
	for (i = 0; i < mask->size; i++) {
		if (numa_bitmask_isbitset(mask, i))
			num_bits++;
	}
	/* Could stash this instead of recomputing every time. */
	return num_bits;
}

/* ajfabbri: I suggest removing libnuma v1 support. */
static inline unsigned int rt_numa_bitmask_isbitset(
	const rt_bitmask_t *affinity_mask, unsigned long i)
{
#if LIBNUMA_API_VERSION >= 2
	return numa_bitmask_isbitset(affinity_mask, i);
#else /* LIBNUMA_API_VERSION == 1 */
	return test_bit(i, affinity_mask);
#endif
}

static inline rt_bitmask_t* rt_numa_parse_cpustring(const char* s) 
{
#if LIBNUMA_API_VERSION >= 2

#ifdef numa_parse_cpustring_all
	return numa_parse_cpustring_all(s);
#else
	/* We really need numa_parse_cpustring_all(), so we can assign threads
	 * to cores which are part of an isolcpus set, but early 2.x versions of
	 * libnuma do not have this function.  A work around should be to run
	 * your command with e.g. taskset -c 9-15 <command>
	 */
	return numa_parse_cpustring(s);
#endif 

#else /* LIBNUMA_API_VERSION == 1 */
	rt_bitmask_t *mask = malloc(sizeof(*mask));
	if (mask) 
		mask->mask = cpumask(s, &mask->size);
	return mask;
#endif
}

static inline void rt_bitmask_free(rt_bitmask_t *mask)
{
#if LIBNUMA_API_VERSION >= 2
	numa_bitmask_free(mask);
#else /* LIBNUMA_API_VERSION == 1 */
	free(mask->mask);
	free(mask);
#endif
}

#else /* ! NUMA */
typedef struct { } rt_bitmask_t;
static inline void *threadalloc(size_t size, int n) { return malloc(size); }
static inline void threadfree(void *ptr, size_t s, int n) { free(ptr); }
static inline void rt_numa_set_numa_run_on_node(int n, int c) { }
static inline void numa_on_and_available() { };
static inline int rt_numa_numa_node_of_cpu(int cpu) { return -1; }
static void *rt_numa_numa_alloc_onnode(size_t s, int n, int c) { return NULL; }
static inline unsigned int rt_numa_bitmask_isbitset(
	const rt_bitmask_t *affinity_mask, unsigned long i) { return 0; }
static inline rt_bitmask_t* rt_numa_parse_cpustring(const char* s) 
{ return NULL; }
static inline unsigned int rt_numa_bitmask_count(const rt_bitmask_t *mask)
{ return 0; }
static inline void rt_bitmask_free(rt_bitmask_t *mask) { return; }

#endif	/* NUMA */

#endif	/* _RT_NUMA_H */
