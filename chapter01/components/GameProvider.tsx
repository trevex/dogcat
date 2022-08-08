import { PropsWithChildren, useState, useEffect, useRef, createContext, useContext, MutableRefObject } from 'react';
import useSWR from 'swr';

export enum Direction {
    Up = 1,
    Down,
    Left,
    Right,
}

export enum Controller {
    Cat = 1,
    Dog,
}

export enum Status {
    Loading = 1, // Currently unused as we ignore the status of loaded images
    NewGame,
    Running,
    Paused,
    Lost,
}

export type Coord = {
    x: number;
    y: number;
};

export type Food = [Coord, string, Controller];

const foodFetcher = (length: number, updateCount: number) =>
    fetch('/api/foods', {
        method: 'POST',
        cache: 'no-cache',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ length, updateCount })
    }).then((res) => res.json());

// Ok, to control the game through the UI, we separate out the "game-state"
// into a react context
type GameContextType = {
    status: Status;
    dogCat: Coord[];
    foods: Food[];
    score: number;
    control: MutableRefObject<Controller>;
    direction: MutableRefObject<Direction>;
    playerName: MutableRefObject<string>;
    rows: number; columns: number;
    resetGame: () => void;
    startGame: () => void;
    resumeGame: () => void;
    pauseGame: () => void;
    stopGame: () => void;
    handleClick: (event: any) => void;
};

const GameContext = createContext<GameContextType | null>(null);

type GameProviderProps = {
    rows: number;
    columns: number;
};

export const useGameContext = () => {
    return useContext(GameContext) as GameContextType;
}

export const GameProvider = ({ rows, columns, children }: PropsWithChildren<GameProviderProps>) => {
    const [status, setStatus] = useState(Status.NewGame);
    const [dogCat, setDogCat] = useState<Coord[]>([]);
    const [foods, setFoods] = useState<Food[]>([]);
    const [score, setScore] = useState(0);
    const [updateCount, setUpdateCount] = useState(0);
    const tickRate = useRef(0);
    const control = useRef(Controller.Dog);
    const direction = useRef(Direction.Right);
    const digesting = useRef(0);
    const playerName = useRef("anonymous");


    const resetGame = () => {
        setDogCat([{ x: 5, y: 5 }, { x: 6, y: 5 }, { x: 7, y: 5 }]);
        setFoods([[{ x: 2, y: 2 }, "sausage", Controller.Dog], [{ x: 10, y: 10 }, "fish", Controller.Cat]]); // tmp
        setScore(0);
        setUpdateCount(0);
        tickRate.current = 200;
        control.current = Controller.Dog;
        direction.current = Direction.Right;
        digesting.current = 10;
    };

    const stopGame = () => {
        setStatus(Status.Lost);
    };

    const resumeGame = () => {
        setStatus(Status.Running);
    };

    const startGame = () => {
        resetGame();
        setStatus(Status.Running);
    };

    const pauseGame = () => {
        setStatus(Status.Paused);
    };


    // Fetch food, when food was eaten
    const { data } = useSWR(foods.length === 0 ? [dogCat.length, updateCount] : null, foodFetcher)
    useEffect(() => {
        if (foods.length === 0 && data !== undefined) {
            if (data.message !== undefined) {
                return;
            }
            tickRate.current = data.tickRate;
            let newFoods = data.foods as Food[];
            let takenCoords: Coord[] = [];
            var j = newFoods.length;
            while (j--) {
                // Create random position
                newFoods[j][0].x = Math.floor(Math.random() * columns);
                newFoods[j][0].y = Math.floor(Math.random() * rows);
                // If already taken, remove food
                const first = takenCoords.find((coord) => {
                    return (coord.x === newFoods[j][0].x && coord.y === newFoods[j][0].y)
                });
                if (first === undefined) {
                    takenCoords.push(newFoods[j][0]);
                } else {
                    newFoods.splice(j, 1);
                    continue
                }
                // If it accidentally collides with player, we remove it
                for (var coord of dogCat) {
                    if (coord.x === newFoods[j][0].x && coord.y === newFoods[j][0].y) {
                        newFoods.splice(j, 1);
                        break;
                    }
                }
            }
            setFoods(newFoods);
        }
    }, [data, foods]);


    const updateDogCat = () => {
        // Let's use the direction and current front element facing towards
        // our next movement to compute the next element.
        const d = direction.current;
        const front = (control.current === Controller.Dog) ? dogCat[dogCat.length - 1] : dogCat[0];
        const next =
            (d === Direction.Right) && { x: front.x + 1, y: front.y } ||
            (d === Direction.Left) && { x: front.x - 1, y: front.y } ||
            (d === Direction.Up) && { x: front.x, y: front.y - 1 } ||
            { x: front.x, y: front.y + 1 };
        // Add the next element either in the front or back dependening on where
        // we are facing.
        // We only remove the element at the back if we are not digesting food.
        // If we are digesting, we are "growing".
        // If it is below 0 we ate something wrong, so let's "shrink".
        if (control.current === Controller.Dog) {
            dogCat.push(next);
            if (digesting.current <= 0) dogCat.shift();
        } else {
            dogCat.unshift(next);
            if (digesting.current <= 0) dogCat.pop();
        }
        // We just digested an element by not removing the back element, so let's
        // substract one.
        if (digesting.current > 0) {
            digesting.current = digesting.current - 1;
        } else if (digesting.current < 0) { // If we ate something wrong, we shrank, so let's add one
            digesting.current = digesting.current + 1;
        }
        setDogCat(dogCat);

        // Let's see if we can eat something:
        let leftovers = [...foods];
        var i = leftovers.length
        const first = dogCat[0], last = dogCat[dogCat.length - 1];
        while (i--) {
            const c = leftovers[i][0];
            if ((c.x === first.x && c.y === first.y) || (c.x === last.x && c.y === last.y)) {
                // We are eating: update digesting, set score and remove food
                digesting.current = digesting.current + (leftovers[i][2] === control.current ? 2 : -2);
                setScore(score + (leftovers[i][2] === control.current ? 100 : -100));
                leftovers.splice(i, 1);
            }
        }
        if (leftovers.length !== foods.length) { // We only update foods, when required
            setFoods(leftovers);
        }


        // Now let's do the collision checks:
        for (var coord of dogCat) { // If any element outside of bounds, we stop
            if (coord.x < 0 || coord.x >= columns || coord.y < 0 || coord.y >= rows) {
                stopGame();
            }
        }
        // If dogcat collides with itself, we stop
        const withoutDuplicates = new Set(dogCat.map(v => v.x + "-" + v.y))
        if (withoutDuplicates.size !== dogCat.length) {
            stopGame();
        }
    };

    const swapControl = () => {
        control.current = (control.current === Controller.Dog) ? Controller.Cat : Controller.Dog;
        // Changing control requires us to also figure out which direction to move back in
        const es = (control.current === Controller.Dog) ? dogCat.slice(-2).reverse() : dogCat.slice(0, 2);
        const dx = es[0].x - es[1].x;
        const dy = es[0].y - es[1].y;
        direction.current =
            (dx > 0) && Direction.Right ||
            (dx < 0) && Direction.Left ||
            (dy > 0) && Direction.Down || Direction.Up;
    };

    const handleKeyDown = (event: KeyboardEvent) => {
        event.preventDefault()
        if (event.code === "KeyP") {
            pauseGame();
        }
        if (event.code === "Space") {
            swapControl();
        }
        // Let's see if we explicitly change direction.
        // We have to make sure direction is "allowed"!
        const c = direction.current
        const d =
            (event.code === "ArrowLeft" && (c === Direction.Up || c === Direction.Down)) && Direction.Left ||
            (event.code === "ArrowRight" && (c === Direction.Up || c === Direction.Down)) && Direction.Right ||
            (event.code === "ArrowUp" && (c === Direction.Left || c === Direction.Right)) && Direction.Up ||
            (event.code === "ArrowDown" && (c === Direction.Left || c === Direction.Right)) && Direction.Down ||
            null;
        if (d !== null) {
            direction.current = d;
        }
    };


    const handleClick = (event: any) => {
        if (status !== Status.Running) return;
        // Event handling is a bit of a pain with so let's assume a native event
        // and check for availability
        if (event.target === undefined || event.target.clientWidth === undefined || event.target.clientHeight === undefined) {
            return;
        }
        const width = event.target.clientWidth, height = event.target.clientHeight;
        let x = 0, y = 0;
        if (event.offsetX !== undefined && event.offsetY !== undefined) { // MouseEvent
            x = event.offsetX;
            y = event.offsetY;
        } else if (event.targetTouches !== undefined && event.targetTouches.length > 0) { // TouchEvent
            var rect = event.target.getBoundingClientRect();
            x = event.targetTouches[0].pageX - rect.left;
            y = event.targetTouches[0].pageY - rect.top;
        } else if (event.changedTouches !== undefined && event.changedTouches.length > 0) { // TouchEvent
            var rect = event.target.getBoundingClientRect();
            x = event.changedTouches[0].pageX - rect.left;
            y = event.changedTouches[0].pageY - rect.top;
        } else {
            return;
        }
        const widthHalf = width / 2, heightHalf = height / 2;
        const dx = width / 10, dy = height / 10;
        const c = direction.current;
        if (c === Direction.Up || c === Direction.Down) { // We can only move left or right
            if (x > widthHalf - dx && x < widthHalf + dx) { // Tapped in the center let's swap
                swapControl();
            } else if (x < widthHalf) { // Left
                direction.current = Direction.Left;
            } else { // Right
                direction.current = Direction.Right;
            }
        } else { // Only up or down
            if (y > heightHalf - dy && y < heightHalf + dy) { // Tapped in the center let's swap
                swapControl();
            } else if (y < heightHalf) { // Up
                direction.current = Direction.Up;
            } else { // Down
                direction.current = Direction.Down;
            }
        }
    };

    // If the game is running, listen to key events
    useEffect(() => {
        if (status === Status.Running) {
            window.addEventListener("keydown", handleKeyDown);
            return () => {
                window.removeEventListener("keydown", handleKeyDown);
            };
        }
        return () => { };
    }, [status]);

    // We need to loop our updates based on the dynamic `tickRate`.
    // The `updateCount` dependency achieves this dynamic looping behavior.
    useEffect(() => {
        if (status === Status.Running && updateCount >= 0) {
            const timeoutId = setTimeout(() => {
                updateDogCat();
                setUpdateCount(updateCount + 1);
            }, tickRate.current);
            return () => clearTimeout(timeoutId);
        }
        return () => { };
    }, [status, updateCount]);


    return <GameContext.Provider value={{ status, dogCat, foods, score, control, direction, rows, columns, resetGame, startGame, stopGame, pauseGame, resumeGame, playerName, handleClick }}>{children}</GameContext.Provider>;
};
