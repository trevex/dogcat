import { PropsWithChildren, useState, useEffect, useRef, createContext, useContext, MutableRefObject } from 'react';

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


// Ok, to control the game through the UI, we separate out the "game-state"
// into a react context
type GameContextType = {
    status: Status; setStatus: (value: Status) => void;
    dogCat: Coord[]; setDogCat: (value: Coord[]) => void;
    foods: Food[]; setFoods: (value: Food[]) => void;
    score: number; setScore: (value: number) => void;
    control: MutableRefObject<Controller>;
    direction: MutableRefObject<Direction>;
    rows: number; columns: number;
    resetGame: () => void;
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

    //     const prevStatusRef = useRef<Status>();
    //     useEffect(() => {
    //         console.log(status, prevStatusRef.current);
    //         prevStatusRef.current = status;
    //     }, [status]);

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
        var i = foods.length
        const first = dogCat[0], last = dogCat[dogCat.length - 1];
        while (i--) {
            const c = foods[i][0];
            if ((c.x === first.x && c.y === first.y) || (c.x === last.x && c.y === last.y)) {
                // We are eating: update digesting, set score and remove food
                digesting.current = digesting.current + (foods[i][2] === control.current ? 2 : -2);
                setScore(score + (foods[i][2] === control.current ? 100 : -100));
                foods.splice(i, 1);
            }
        }
        setFoods(foods);


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

    const handleKeyDown = (event: KeyboardEvent) => {
        event.preventDefault()
        if (event.code === "KeyP") {
            setStatus(Status.Paused);
        }
        // Changing control requires us to also figure out which direction to move back in
        if (event.code === "Space") {
            control.current = (control.current === Controller.Dog) ? Controller.Cat : Controller.Dog;
            const es = (control.current === Controller.Dog) ? dogCat.slice(-2).reverse() : dogCat.slice(0, 2);
            const dx = es[0].x - es[1].x;
            const dy = es[0].y - es[1].y;
            direction.current =
                (dx > 0) && Direction.Right ||
                (dx < 0) && Direction.Left ||
                (dy > 0) && Direction.Down || Direction.Up;
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

    return <GameContext.Provider value={{ status, setStatus, dogCat, setDogCat, foods, setFoods, score, setScore, control, direction, rows, columns, resetGame }}>{children}</GameContext.Provider>;
};
