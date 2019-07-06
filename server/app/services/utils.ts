export function mapObject<T,R>(mapper: (o: T) => R) {
  return (obj: T) => {
    return mapper(obj);
  }
}

export function atob(b64) {
  return Buffer.from(b64, 'base64').toString();
}

export function randomIntFromInterval(min,max) {// min and max included 
    return Math.floor(Math.random()*(max-min+1)+min);
}