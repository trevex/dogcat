import React, { ReactElement, useState, useEffect, useRef } from 'react';
import { Stage, Layer, Rect, Image, Line, Text } from 'react-konva';
import useImage from 'use-image';


enum Direction {
    Up = 1,
    Down,
    Left,
    Right,
}

enum Controller {
    Cat = 1,
    Dog,
}

enum Status {
    Loading = 1, // Currently unused as we ignore the status of loaded images
    NewGame,
    Running,
    Paused,
    Lost,
}

type Coord = {
    x: number;
    y: number;
};

type GameProps = {
    size: number;
    cells: number;
};


// Well we should probably use proper numbers, but for now we lerp on hex strings...
const lerpColor = (a: string, b: string, amount: number) => {
    let ah = parseInt(a.replace(/#/g, ''), 16),
        ar = ah >> 16, ag = ah >> 8 & 0xff, ab = ah & 0xff,
        bh = parseInt(b.replace(/#/g, ''), 16),
        br = bh >> 16, bg = bh >> 8 & 0xff, bb = bh & 0xff,
        rr = ar + amount * (br - ar),
        rg = ag + amount * (bg - ag),
        rb = ab + amount * (bb - ab);
    return '#' + ((1 << 24) + (rr << 16) + (rg << 8) + rb | 0).toString(16).slice(1);
}


const Game = ({
    size,
    cells
}: GameProps) => {
    const gridColor0 = "#eeeeee";
    const gridColor1 = "#dddddd";
    const dogColor = "#9f6d20";
    const catColor0 = "#7fb0e3";
    const height = size, width = size;   // Only a square as level supported,
    const rows = cells, columns = cells; // so w == h and c == r!
    const gridSize = size / cells;
    const headExtraSize = gridSize / 1.8;
    const headExtraSizeHalf = headExtraSize / 2;


    // Our game state
    const [status, setStatus] = useState(Status.NewGame);
    const [dogCat, setDogCat] = useState<Coord[]>([]);
    const [updateCount, setUpdateCount] = useState(0);
    const tickRate = useRef(0);
    const control = useRef(Controller.Dog);
    const direction = useRef(Direction.Right);
    const digesting = useRef(0);

    // Our assets
    const [dog] = useImage("/dog.png", 'anonymous');
    const [cat] = useImage("/cat.png", 'anonymous');

    const resetGame = () => {
        setDogCat([{ x: 5, y: 5 }, { x: 6, y: 5 }, { x: 7, y: 5 }]);
        setUpdateCount(0);
        tickRate.current = 200;
        control.current = Controller.Dog;
        direction.current = Direction.Right;
        digesting.current = 10;
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
        if (control.current === Controller.Dog) {
            dogCat.push(next);
            if (digesting.current === 0) dogCat.shift();
        } else {
            dogCat.unshift(next);
            if (digesting.current === 0) dogCat.pop();
        }
        // We just digested an element by not removing the back element, so let's
        // substract one.
        if (digesting.current > 0) {
            digesting.current = digesting.current - 1;
        }
        setDogCat(dogCat)
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


    // Let's draw our background chessboard grid
    let gridElements: ReactElement[] = [];
    for (let x = 0; x < columns; x++) {
        for (let y = 0; y < rows; y++) {
            let fill = gridColor0;
            if (x % 2 == 0 && y % 2 == 0) {
                fill = gridColor1;
            } else if (x % 2 != 0 && y % 2 != 0) {
                fill = gridColor1;
            }
            gridElements.push(<Rect
                key={x + "-" + y + "-" + gridElements.length}
                x={x * gridSize} y={y * gridSize}
                width={gridSize} height={gridSize}
                fill={fill}
            />);
        }
    }

    // Let's draw the DogCat character
    let dogCatElements: ReactElement[] = [];
    for (var coord of dogCat) {
        const length = dogCatElements.length;
        if (length === 0 || length === dogCat.length - 1) {
            // At the beginning and end we draw the heads
            dogCatElements.push(<Image
                key={"dogcat-" + length}
                image={(length === 0) ? cat : dog}
                x={coord.x * gridSize - headExtraSizeHalf} y={coord.y * gridSize - headExtraSizeHalf}
                width={gridSize + headExtraSize} height={gridSize + headExtraSize}
            />);
        } else { // Inbetween we draw the elemnts and lerp between the colors
            const fill = lerpColor(catColor0, dogColor, length / (dogCat.length - 1));
            const elementSize = gridSize - 2;
            dogCatElements.push(<Line
                key={coord.x + "-" + coord.y + "-" + length}
                x={coord.x * gridSize} y={coord.y * gridSize}
                fill={fill} stroke="#000" strokeWidth={gridSize / 16}
                points={[0, 0, elementSize, 0, elementSize, elementSize, 0, elementSize]}
                tension={0.2} closed
            />);
        }
    }
    // Let's re-insert cat at the back to make sure zIndex is above body
    const catElement = dogCatElements[0];
    dogCatElements.splice(0, 1);
    dogCatElements.push(catElement);

    // Finally let's draw the UI components
    let uiElements: ReactElement[] = [];
    const fontSize = gridSize;
    const uiSize = gridSize * 10;
    const uiSizeHalf = uiSize / 2;
    if (status === Status.Paused) {
        const resume = () => {
            setStatus(Status.Running);
        };
        uiElements.push(<Rect
            key="pauserect" onMouseDown={resume}
            x={width / 2 - uiSizeHalf} y={height / 2 - uiSizeHalf}
            width={uiSize} height={uiSize}
            fill="orange" stroke="black" opacity={0.9}
        />);
        uiElements.push(<Text
            key="pausetext" text="Resume" onMouseDown={resume}
            fontSize={fontSize} fill="#fff"
            x={width / 2 - uiSizeHalf + fontSize * 3} y={height / 2 - fontSize / 2}
        />);
    } else if (status === Status.Loading) {
        uiElements.push(<Rect
            key="loadrect"
            x={width / 2 - uiSizeHalf} y={height / 2 - uiSizeHalf}
            width={uiSize} height={uiSize}
            fill="yellow" stroke="black" opacity={0.9}
        />);
        uiElements.push(<Text
            key="loadtext" text="Loading..."
            fontSize={fontSize} fill="#fff"
            x={width / 2 - uiSizeHalf} y={height / 2 - fontSize / 2}
        />);
    } else if (status === Status.NewGame) {
        const startGame = () => {
            resetGame();
            setStatus(Status.Running);
        };
        uiElements.push(<Rect
            key="newgamerect" onMouseDown={startGame}
            x={width / 2 - uiSizeHalf} y={height / 2 - uiSizeHalf}
            width={uiSize} height={uiSize}
            fill="green" stroke="black" opacity={0.9}
        />);
        uiElements.push(<Text
            key="newgametext" text="Start Game" onMouseDown={startGame}
            fontSize={fontSize} fill="#fff"
            x={width / 2 - uiSizeHalf + fontSize * 2.5} y={height / 2 - fontSize / 2}
        />);
    }

    return (
        <Stage width={width} height={height}>
            <Layer>
                {gridElements}
            </Layer>
            <Layer>
                {dogCatElements}
            </Layer>
            <Layer>
                {uiElements}
            </Layer>
        </Stage>
    );
};

export default Game;
