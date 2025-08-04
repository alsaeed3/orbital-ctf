'use client';

import dynamic from 'next/dynamic';
import React from 'react';

interface NoSSRProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

/**
 * NoSSR component to prevent hydration mismatches for client-only components
 * Use sparingly and only when hydration issues cannot be resolved otherwise
 */
function NoSSRComponent({ children, fallback = null }: NoSSRProps) {
  const [hasMounted, setHasMounted] = React.useState(false);

  React.useEffect(() => {
    setHasMounted(true);
  }, []);

  if (!hasMounted) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
}

const NoSSR = dynamic(() => Promise.resolve(NoSSRComponent), {
  ssr: false
});

export default NoSSR;
