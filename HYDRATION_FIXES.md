# Hydration Issues Fixed

This document tracks the hydration issues that were identified and resolved in the Orbital CTF platform.

## What is Hydration?

Hydration is the process where React attaches event listeners and makes a server-rendered page interactive. Hydration mismatches occur when the server-rendered HTML doesn't match what React expects on the client side.

## Issues Fixed

### 1. Navbar Component - localStorage Access
**Problem**: The component was checking `typeof window !== 'undefined'` and accessing localStorage during initialization, causing server/client mismatch.

**Solution**: 
- Added a `mounted` state to track when the component has hydrated
- Moved localStorage access to a useEffect that runs after hydration
- Only apply DOM changes after the component is mounted

### 2. ConfigurationTab & GameConfigurationTab - Date.now() Usage
**Problem**: Components were initializing state with `new Date(Date.now() + ...)` which creates different timestamps on server vs client.

**Solution**:
- Initialize date states as `null` to avoid mismatch
- Set default values after the component mounts via useEffect
- Only calculate dates on the client side

### 3. GameClock Component - Date Initialization
**Problem**: Component was initializing `currentTime` with `new Date()` which differs between server and client.

**Solution**:
- Initialize `currentTime` as `null`
- Set the actual date in useEffect after hydration
- Added null checks for all date operations

## Best Practices to Avoid Hydration Issues

1. **Avoid time-based initialization**: Don't use `Date.now()`, `new Date()`, or `Math.random()` in initial state
2. **Use useEffect for client-only code**: Move localStorage, window, or document access to useEffect
3. **Initialize with stable values**: Use null, empty strings, or consistent defaults for initial state
4. **Add hydration guards**: Use a `mounted` state to prevent client-only code from running during SSR

## NoSSR Component

A `NoSSR` component has been created at `src/components/common/NoSSR.tsx` for cases where hydration issues cannot be completely resolved. Use this sparingly and only as a last resort:

```tsx
import NoSSR from '@/components/common/NoSSR';

<NoSSR fallback={<div>Loading...</div>}>
  <ClientOnlyComponent />
</NoSSR>
```

## Testing for Hydration Issues

1. Run `pnpm run dev`
2. Check the browser console for hydration warnings
3. Look for text mismatches or unexpected DOM structure differences
4. Test with disabled JavaScript to verify SSR content matches expected output

## Additional Resources

- [Next.js Hydration Documentation](https://nextjs.org/docs/messages/react-hydration-error)
- [React Hydration Guide](https://react.dev/reference/react-dom/client/hydrateRoot)
