import { createHash } from 'crypto'

function stableValue<T>(obj: T): [string, unknown][] | T | null {
    if (typeof obj === 'object' && obj !== null && !Array.isArray(obj)) {
        return Object.entries(obj)
            .sort(([a], [b]) => (a < b ? -1 : 1))
            .filter(([, x]) => x !== undefined)
            .map(([n, x]) => [n, stableValue(x)])
    }
    return obj ?? null
}

export function stableHash<T>(obj: T): string {
    const hasher = createHash('sha256')
    hasher.update(JSON.stringify(stableValue(obj)))
    return hasher.digest('hex')
}
