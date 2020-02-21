import { getOwner } from 'discourse-common/lib/get-owner';
import { next } from "@ember/runloop";
import DiscourseURL from 'discourse/lib/url';

const contentLanguageParam = 'content_languages';
const localeParam = "locale";
const discoveryParams = [contentLanguageParam];

function getRouter(ctx) {
  const router = getOwner(ctx).lookup("router:main");
  return router;
}

function getDiscoveryController(ctx) {
  const controller = getOwner(ctx).lookup(`controller:discovery/topics`);
  return controller;
}

function getDiscoveryParam(ctx, paramName) {
  return getDiscoveryController(ctx).get(paramName);
}

function setDiscoveryParam(ctx, paramName, value) {
  getDiscoveryController(ctx).set(paramName, value);
}

function getPath(ctx) {
  const path = getRouter(ctx).currentURL.toString();
  return path;
}

function getParams(ctx, paramName = null) {
  let parts = getPath(ctx).split('?')
  let queryParams = parts.length > 1 ? parts[1] : '';
  let params = new URLSearchParams(queryParams);
  return paramName ? params.get(paramName) : params;
}

function buildPath(ctx, params) {
  let parts = getPath(ctx).split('?')
  parts[1] = params.toString();
  return parts.filter(p => p.length).join('?');
}

function useDiscoveryController(ctx, paramName) {
  return getRouter(ctx).currentRouteName.indexOf('discovery') > -1 && 
    discoveryParams.indexOf(paramName) > -1
}

// same as DiscourseURL.replaceState besides allowing modification of current path
function replaceState(path) {
  if (window.history &&
      window.history.pushState &&
      window.history.replaceState) {
    next(() => {
      const location = DiscourseURL.get("router.location");
      if (location && location.replaceURL) {
        location.replaceURL(path);
      }
    });    
  }
}

function addParam(paramName, value, opts = {}) {
  if (opts.add_cookie) {
    $.cookie(`discourse_${paramName}`, value);
  }
  
  if (useDiscoveryController(opts.ctx, paramName)) {
    return setDiscoveryParam(opts.ctx, paramName, value);
  }
  
  const params = getParams(opts.ctx);
  params.delete(paramName);
  if (value) params.set(paramName, value);
              
  window.location.href = buildPath(opts.ctx, params);
  
  return value;
}

function removeParam(paramName, opts = {}) {
  const router = getRouter(opts.ctx);
  
  const params = getParams(opts.ctx);
  let value = params.get(paramName);
  
  if (!value) return null;
  
  if (useDiscoveryController(opts.ctx, paramName)) {
    return setDiscoveryParam(opts.ctx, null);
  }
  
  params.delete(paramName);
      
  replaceState(buildPath(opts.ctx, params));
        
  return value;
}

export {
  getRouter,
  addParam,
  removeParam,
  getParams,
  getDiscoveryParam,
  setDiscoveryParam,
  contentLanguageParam,
  discoveryParams,
  localeParam
};