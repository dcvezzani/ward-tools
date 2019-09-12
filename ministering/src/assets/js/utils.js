'use strict';

export const sort_by_name = (a,b) => a.name.localeCompare(b.name);
export const sort_by = (field) => (a,b) => a[field].localeCompare(b[field]);

